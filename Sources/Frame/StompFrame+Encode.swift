//
// StompFrame+Encode.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import NIOCore

struct StompFrameEncoder: MessageToByteEncoder {
    typealias OutboundIn = StompClientFrame
    
    func encode(data: StompClientFrame, out: inout ByteBuffer) throws {
        out.writeString(data.command.rawValue)
        out.writeBytes([LINEFEED_BYTE])
        
        for header in data.headers.lookup {
            out.writeString(header.key.description)
            out.writeBytes([COLON_BYTE])
            out.writeString(header.value)
            out.writeBytes([LINEFEED_BYTE])
        }
        
        out.writeBytes([LINEFEED_BYTE])
        out.writeBytes(data.body)
        out.writeBytes([NULL_BYTE])
    }
}
