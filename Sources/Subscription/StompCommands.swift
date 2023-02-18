//
// StompCommands.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

public extension StompCommandable {
    // MARK: - Transaction
    
    /// A transaction allows you to group multiple frames, which can then either be applied or reverted.
    ///
    /// ```swift
    /// try await stomp.transaction { tx in
    ///     tx.ack()
    ///     tx.send()
    ///     return .abort
    /// }
    /// ```
    func transaction(
        named name: String,
        headers: StompHeaderDictionary = [:],
        closure: @escaping (StompCommandable) async throws -> StompTransactionResult
    ) async throws {
        guard let subscriptionId = subscriptionId else {
            throw StompError.missingSubscription
        }
        
        let headers = baseHeaders.adding(headers).adding([
            .transaction: name,
        ])
        
        try await stomp.send(command: .BEGIN, headers: headers, body: nil)
        
        let transaction = StompTransaction(
            transactionName: name,
            subscriptionId: subscriptionId,
            stomp: stomp
        )
        
        let result = try await closure(transaction)
        
        switch result {
        case .abort:
            try await stomp.send(command: .ABORT, headers: headers, body: nil)
            
        case .commit:
            try await stomp.send(command: .COMMIT, headers: headers, body: nil)
        }
    }
    
    // MARK: - ACK
    
    func ack(frame: StompFrame, headers: StompHeaderDictionary = [:]) async throws {
        guard let ackId = frame.headers.ack else {
            throw StompError.missingAckId
        }
        
        let headers = baseHeaders.adding(headers).adding([
            .id: ackId,
        ])
        
        try await stomp.send(command: .ACK, headers: headers, body: nil)
    }
    
    func ack(id: String, headers: StompHeaderDictionary = [:]) async throws {
        let headers = baseHeaders.adding(headers).adding([
            .id: id,
        ])
        
        try await stomp.send(command: .ACK, headers: headers, body: nil)
    }
    
    // MARK: - NACK
    
    func nack(frame: StompFrame, headers: StompHeaderDictionary = [:]) async throws {
        guard let ackId = frame.headers.ack else {
            throw StompError.missingAckId
        }
        
        let headers = baseHeaders.adding(headers).adding([
            .id: ackId,
        ])
        
        try await stomp.send(command: .NACK, headers: headers, body: nil)
    }
    
    func nack(id: String, headers: StompHeaderDictionary = [:]) async throws {
        let headers = baseHeaders.adding(headers).adding([
            .id: id,
        ])
        
        try await stomp.send(command: .NACK, headers: headers, body: nil)
    }
    
    // MARK: - SEND
    
    /// SEND
    ///
    /// **Headers**
    /// - destination (required)
    /// - content-type
    /// - content-length
    func send(destination: String, body: Data, contentType: String, headers: StompHeaderDictionary = [:]) async throws {
        let headers = baseHeaders.adding(headers).adding([
            .destination: destination,
            .contentType: contentType,
            .contentLength: "\(body.count)",
        ])
        
        try await stomp.send(command: .SEND, headers: headers, body: body)
    }
    
    /// SEND
    ///
    /// **Headers**
    /// - destination (required)
    func send(destination: String, headers: StompHeaderDictionary = [:]) async throws {
        let headers = baseHeaders.adding(headers).adding([
            .destination: destination,
        ])
        
        try await stomp.send(command: .SEND, headers: headers, body: nil)
    }
    
    // MARK: - UNSUBSCRIBE
    
    func unsubscribe(headers: StompHeaderDictionary = [:]) async throws {
        guard let subscriptionId = subscriptionId else {
            throw StompError.missingSubscription
        }
        
        stomp.cleanupSubscription(id: subscriptionId)
        
        let headers = baseHeaders.adding(headers).adding([
            .id: subscriptionId,
        ])
        
        try await stomp.send(command: .UNSUBSCRIBE, headers: headers, body: nil)
    }
    
    // MARK: - DISCONNECT
    
    func disconnect() async throws {
        try await stomp.disconnect()
    }
    
    // MARK: - Internal Logic
    
    internal var baseHeaders: StompHeaderDictionary {
        if let transactionName = transactionName {
            return [
                .transaction: transactionName,
            ]
        }
        
        return [:]
    }
}

extension StompHeaderDictionary {
    func adding(_ headers: StompHeaderDictionary) -> Self {
        merging(headers, uniquingKeysWith: { lhs, _ in lhs })
    }
}
