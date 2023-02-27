//
// STOMP.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import Logging
import NIOCore
import NIOConcurrencyHelpers

public final class STOMP: StompExecutable {
    private let logger = Logger(label: LABEL_PREFIX)
    private let connection: StompConnection
    private let communication: StompCommunication
    private let subscriptionLock = NIOLock()
    
    // MARK: - Configuration
    
    /// Determines whether or not the client wants to send a heartbeat.
    public var heartbeat: StompHeartbeat?
    
    /// Determines when the status of asynchronous functions is returned to the client.
    ///
    /// When `true`, responses will not be returned until a receipt has been received from the server confirming the message sent has been processed.
    /// When `false` (default), responses will be returned as soon as we have sent the message to the server. We assume it has been processed.
    public var waitForReceipt: Bool = true
    
    /// Determines whether or not the STOMP client should automatically reconnect to the server in the event that the connection is lost.
    ///
    /// When enabled, your subscriptions will be automatically reinstated.
    public var reconnectionOptions: StompReconnectionOptions = .disabled
    
    /// Determines the number of seconds to wait before failing a receipt check.
    ///
    /// When `nil`, no timeout is used and it will perpetually wait.
    public var receiptTimeout: TimeInterval? = 15
    
    /// Determines the base headers which are added to every frame sent to the server.
    ///
    /// By default, this is empty, meaning no extra headers will be sent.
    public var defaultHeaders: StompHeaderDictionary = [:]
    
    /// Optional delegate for receiving critical lifecycle events.
    public var delegate: StompDelegate?
    
    // MARK: - Initialisation
    
    public static func create(host: String, port: Int, using eventLoopGroup: EventLoopGroup) -> STOMP {
        STOMP(host: host, port: port, eventLoopGroup: eventLoopGroup)
    }
    
    private init(host: String, port: Int, eventLoopGroup: EventLoopGroup) {
        let communication = StompCommunication()
        
        self.communication = communication
        connection = StompConnection(host: host, port: port, eventLoopGroup: eventLoopGroup, communication: communication)
        connection.commandable = StompSubscription(stomp: self, subscriptionId: nil)
    }
    
    // MARK: - Public
    
    public func connect(
        username: String? = nil,
        password: String? = nil,
        headers: StompHeaderDictionary = [:]
    ) async throws {
        logger.debug("STOMP connection requested")
        try await connection.connect(username: username, password: password, heartbeat: heartbeat, headers: headers)
        setupHeartbeat()
    }
    
    public func disconnect() async throws {
        logger.debug("disconnection requested")
        
        heartbeatTask?.cancel()
        heartbeatTask = nil
        
        try await send(command: .DISCONNECT)
        try await connection.stop()
        
        communication.subscriptions.removeAll()
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
        
        let recovery = StompRecoverableSubscription(
            destination: destination,
            id: id,
            ack: ack,
            headers: headers
        )
        
        let headers = defaultHeaders.adding(headers).adding([
            .id: id,
            .ack: ack.rawValue,
            .destination: destination,
        ])
        
        subscriptionLock.lock()
        communication.subscriptions[id] = closure
        subscriptionLock.unlock()
        
        try await send(command: .SUBSCRIBE, headers: headers)
        
        return StompSubscription(stomp: self, subscriptionId: id)
    }
    
    public func cleanupSubscription(id: String) {
        subscriptionLock.lock()
        communication.subscriptions[id] = nil
        subscriptionLock.unlock()
    }
    
    public func send(command: StompCommand, headers: StompHeaderDictionary = [:], body: Data? = nil) async throws {
        let receipt = UUID().uuidString
        let headers = defaultHeaders.adding(headers).adding(
            waitForReceipt ? [ .receipt: receipt ] : [:]
        )
        
        let frame = StompClientFrame(command: command, headers: headers, body: body)
        
        try await awaitReceipt(receipt: receipt) {
            try await self.connection.send(frame: frame)
        }
    }
    
    internal func awaitReceipt(receipt: String, _ closure: @escaping () async throws -> Void) async throws {
        let block: @Sendable () async throws -> Void = {
            try await withCheckedThrowingContinuation { continuation in
                self.logger.debug("awaiting receipt with ID: \(receipt)", metadata: [
                    "receipt": .string(receipt),
                ])

                self.communication.continuationLock.lock()
                self.communication.continuations[receipt] = continuation
                self.communication.continuationLock.unlock()
                
                Task.detached(priority: .high) {
                    do {
                        try await closure()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        if waitForReceipt == false {
            // call closure, no waiting around
            try await closure()
        } else if let timeout = receiptTimeout {
            // call block (which calls closure) but with a timeout
            try await withTimeout(seconds: timeout, operation: block)
        } else {
            // call block (which calls closure) with no timeout
            try await block()
        }
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

struct StompRecoverableSubscription {
    let destination: String
    let id: String
    let ack: StompAckMode
    let headers: StompHeaderDictionary
}
