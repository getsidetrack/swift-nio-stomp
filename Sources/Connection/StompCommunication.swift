//
// StompCommunication.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import Logging

public typealias StompMessageCallback = @Sendable (StompFrame) async throws -> Void

final class StompCommunication {
    private let logger = Logger(label: LABEL_PREFIX + ".communication")
    
    var subscriptions = [String: StompMessageCallback]()
    var continuations = [String: UnsafeContinuation<Void, Never>]()
    
    func onError(_ error: Error) {
        logger.error("error: \(error.localizedDescription)")
    }
    
    func onFrame(_ frame: StompFrame) {
        if frame.command == .CONNECTED {
            logger.notice("STOMP client is connected.", metadata: [
                "session": .string(frame.headers.session ?? "unknown")
            ])
            
            return
        }
        
        if frame.command == .RECEIPT {
            guard let id = frame.headers.allValues[.receiptId] ?? nil else {
                logger.warning("receipt received with no identifier")
                return
            }
            
            guard let continuation = continuations[id] else {
                logger.warning("receipt received with no continuation pending", metadata: [
                    "receipt": .string(id)
                ])
                
                return
            }
            
            logger.debug("resuming continuation for receipt with ID: \(id)", metadata: [
                "receipt": .string(id)
            ])
            
            continuation.resume()
            
            // cleanup memory
            continuations[id] = nil
            return
        }
        
        frameCounter.increment()
        
        guard let subscriptionId = frame.headers.subscription else {
            logger.debug("message received bound to no subscription", metadata: [
                "command": .string(frame.command.rawValue)
            ])
            
            return
        }
        
        guard let callback = subscriptions[subscriptionId] else {
            logger.warning("message sent to unknown subscription", metadata: [
                "command": .string(frame.command.rawValue),
                "subscription": .string(subscriptionId)
            ])
            
            return
        }
        
        Task.detached {
            do {
                try await callback(frame)
            } catch {
                frameErrorCounter.increment()
                self.logger.report(error: error)
            }
        }
    }
}
