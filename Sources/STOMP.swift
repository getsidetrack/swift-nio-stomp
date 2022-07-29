//
// STOMP.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import Logging
import NIOCore

public final class STOMP: StompExecutable {
    private let logger = Logger(label: LABEL_PREFIX)
    private let connection: StompConnection
    private let communication: StompCommunication
    
    // MARK: - Configuration
    
    /// Determines whether or not the client wants to send a heartbeat.
    public var heartbeat: StompHeartbeat?
    
    /// Determines when the status of asynchronous functions is returned to the client.
    ///
    /// When `true`, responses will not be returned until a receipt has been received from the server confirming the message sent has been processed.
    /// When `false` (default), responses will be returned as soon as we have sent the message to the server. We assume it has been processed.
    public var waitForReceipt: Bool = false
    
    /// Determines whether or not the STOMP client should automatically reconnect to the server in the event that the connection is lost.
    ///
    /// When enabled, your subscriptions will be automatically reinstated.
    public var reconnectionOptions: StompReconnectionOptions = .disabled
    
    /// Determines the number of seconds to wait before failing a receipt check.
    ///
    /// When `nil`, no timeout is used and it will perpetually wait.
    public var receiptTimeout: TimeInterval? = 30
    
    /// Determines the base headers which are added to every frame sent to the server.
    ///
    /// By default, this is empty, meaning no extra headers will be sent.
    public var defaultHeaders: StompHeaderDictionary = [:]
    
    // MARK: - Initialisation
    
    public static func create(host: String, port: Int, using eventLoopGroup: EventLoopGroup) -> STOMP {
        STOMP(host: host, port: port, eventLoopGroup: eventLoopGroup)
    }
    
    private init(host: String, port: Int, eventLoopGroup: EventLoopGroup) {
        let communication = StompCommunication()
        
        self.communication = communication
        self.connection = StompConnection(host: host, port: port, eventLoopGroup: eventLoopGroup, communication: communication)
        self.connection.commandable = StompSubscription(stomp: self, subscriptionId: nil)
    }
    
    // MARK: - Public
    
    public func connect(
        username: String? = nil,
        password: String? = nil,
        headers: StompHeaderDictionary = [:]
    ) async throws {
        logger.debug("connection requested")
        try await self.connection.connect(username: username, password: password, heartbeat: heartbeat, headers: headers)
        setupHeartbeat()
    }
    
    public func disconnect() async throws {
        logger.debug("disconnection requested")
        
        heartbeatTask?.cancel()
        heartbeatTask = nil
        
        let receipt = "receipt-\(UUID().uuidString)"
        
        try await send(command: .DISCONNECT, headers: [
            .receipt: receipt,
        ], body: nil)
        
        try await awaitReceipt(receipt: receipt)
        try await connection.stop()
    }
    
    @discardableResult
    public func subscribe(
        destination: String,
        id: String? = nil,
        ack: StompAckMode = .auto,
        headers: StompHeaderDictionary = [:],
        onMessage closure: @escaping StompMessageCallback
    ) async throws -> StompCommandable {
        logger.debug("subscription requested")
        
        let id = id ?? UUID().uuidString
        
        let headers = defaultHeaders.adding(headers).adding([
            .id: id,
            .ack: ack.rawValue,
            .destination: destination,
        ])
        
        try await send(command: .SUBSCRIBE, headers: headers, body: nil)
        // TODO: should this await receipt?
        communication.subscriptions[id] = closure
        
        return StompSubscription(stomp: self, subscriptionId: id)
    }
    
    public func send(command: StompCommand, headers: StompHeaderDictionary, body: Data?) async throws {
        let frame = StompClientFrame(command: command, headers: headers, body: body)
        try await connection.send(frame: frame)
    }
    
    internal func awaitReceipt(receipt _: String) async throws {
        // TODO: add ability to generate EventLoopPromise confirming receipt
        // TODO: support timeout of receipts (error)
    }
    
    var heartbeatTask: RepeatedTask?
    
    internal func setupHeartbeat() {
        guard let heartbeat = heartbeat else {
            return
        }
        
        let eventLoop = connection.eventLoopGroup.next()
        let timeAmount = TimeAmount.milliseconds(Int64(heartbeat.send))
        
        heartbeatTask = eventLoop.scheduleRepeatedAsyncTask(initialDelay: timeAmount, delay: timeAmount) { _ in
            let promise = eventLoop.makePromise(of: Void.self)
            
            promise.completeWithTask {
                try await self.send(
                    command: .SEND,
                    headers: [.destination: "*"],
                    body: nil
                )
            }
            
            return promise.futureResult
        }
    }
}
