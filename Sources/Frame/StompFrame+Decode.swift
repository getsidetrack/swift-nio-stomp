//
// StompFrame+Decode.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import Logging
import NIOCore

struct StompFrameDecoder: ByteToMessageDecoder {
    typealias InboundOut = StompFrame
    
    let executable: StompCommandable
    
    private let logger = Logger(label: LABEL_PREFIX + ".frameDecoder")
    
    func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard buffer.readableBytes >= 5 else {
            return .needMoreData
        }
        
        if let frame = parse(buffer: &buffer) {
            context.fireChannelRead(wrapInboundOut(frame))
            return .continue
        }
        
        return .needMoreData
    }
    
    func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF _: Bool) throws -> DecodingState {
        try decode(context: context, buffer: &buffer)
    }
    
    func extractCommand(lines: inout [String]) -> StompCommand? {
        repeat {
            let line = lines.removeFirst()
            
            if let command = StompCommand(rawValue: line) {
                return command
            }
        } while lines.isEmpty == false
        
        return nil
    }
    
    func parse(buffer: inout ByteBuffer) -> StompFrame? {
        let remainingLength = buffer.getLength(untilPatternFound: [LINEFEED_BYTE, LINEFEED_BYTE])
        
        guard remainingLength > 0 else {
            return nil
        }
        
        guard let remainingString = buffer.getString(at: buffer.readerIndex, length: remainingLength) else {
            return nil
        }
        
        var lines = remainingString.components(separatedBy: .newlines)
        guard lines.isEmpty == false else {
            return nil
        }
        
        guard let command = extractCommand(lines: &lines) else {
            if remainingString.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                print("🔴", remainingString, lines)
            }
            
            return nil
        }
        
        logger.trace("decoding \(command.rawValue) frame")
        
        let headers: [StompHeaderKey: String] = lines
            .filter { $0.isEmpty == false }
            .compactMap { line -> (key: StompHeaderKey, value: String)? in
                guard let colonIndex = line.firstIndex(of: ":") else {
                    logger.error("expected header line does not contain colon")
                    return nil
                }
                
                return (
                    StompHeaderKey(value: String(line[..<colonIndex])),
                    String(line[colonIndex...].dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
                        // \c (octet 92 and 99) translates to : (octet 58)
                        .replacingOccurrences(of: "\\c", with: ":")
                )
            }
            .reduce(into: [:]) { $0[$1.0] = $1.1 }
        
        guard let contentLength = headers[.contentLength].flatMap({ Int($0) }) else {
            logger.trace("frame has no content-length")
            
            let predictedLength = buffer.getLength(untilPatternFound: [ NULL_BYTE, LINEFEED_BYTE ], offset: remainingLength)
            
            if predictedLength == 0 {
                // Unable to find the end of the body.
                return nil
            }
            
            buffer.moveReaderIndex(forwardBy: remainingLength)
            let bytes = buffer.readBytes(length: predictedLength) ?? []
            
            return StompFrame(command: command, headers: headers, body: Data(bytes), executable: executable)
        }
        
        // Need to decode body
        logger.trace("frame has content length: \(contentLength)")
        
        guard let bytes = buffer.getBytes(at: buffer.readerIndex + remainingLength, length: contentLength) else {
            // we need more bytes!
            return nil
        }
        
        buffer.moveReaderIndex(forwardBy: remainingLength)
        buffer.moveReaderIndex(forwardBy: min(buffer.writerIndex - buffer.readerIndex, contentLength + 2))
        
        return StompFrame(command: command, headers: headers, body: Data(bytes), executable: executable)
    }
}

extension ByteBuffer {
    func getLength(untilPatternFound pattern: [UInt8], offset: Int = 0) -> Int {
        for i in 0 ..< readableBytes - offset {
            if getBytes(at: i + offset, length: pattern.count) == pattern {
                return i + pattern.count
            }
            
            if readerIndex != 0, getBytes(at: readerIndex + i + offset, length: pattern.count) == pattern {
                return i + pattern.count
            }
        }
        
        return 0
    }
}

extension Array where Element == UInt8 {
 func bytesToHex(spacing: String) -> String {
   var hexString: String = ""
   var count = self.count
   for byte in self
   {
       hexString.append(String(format:"%02X", byte))
       count = count - 1
       if count > 0
       {
           hexString.append(spacing)
       }
   }
   return hexString
}
}
