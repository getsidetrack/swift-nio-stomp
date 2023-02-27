//
// StompConnection.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import Logging
import NIOCore
import NIOPosix

internal final class StompConnection {
    let host: String
    let port: Int
    let eventLoopGroup: EventLoopGroup
    let communication: StompCommunication
    
    var commandable: StompCommandable!
    
    init(host: String, port: Int, eventLoopGroup: EventLoopGroup, communication: StompCommunication) {
        self.host = host
        self.port = port
        self.eventLoopGroup = eventLoopGroup
        self.communication = communication
        
        handler.connection = self
    }
    
    private let logger = Logger(label: LABEL_PREFIX + ".connection")
    
    let handler = StompHandler()
    var channel: Channel?
    private var isInStartupLoop: Bool = false
    
    private func start() async throws {
        if let channel, channel.isActive, channel.isWritable {
            logger.info("unnecessarily attempting to start STOMP connection")
            return
        }
        
        handler.communication = communication
        
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .channelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
            .channelOption(ChannelOptions.connectTimeout, value: TimeAmount.seconds(8))
            .channelInitializer {
                $0.pipeline.addHandlers([
                    MessageToByteHandler(StompFrameEncoder()),
                    ByteToMessageHandler(StompFrameDecoder(executable: self.commandable)),
                    self.handler,
                ])
            }
        
        do {
            logger.info("making connection attempt to \(host):\(port)")
            connectionCounter.increment()
            channel = try await bootstrap.connect(host: host, port: port).get()
        } catch let error as NIOConnectionError {
            // map down to the first connection error as it's usually enough
            throw error.connectionErrors.map(\.error).first ?? error
        }
    }
    
    func stop() async throws {
        guard let channel = channel else {
            return
        }
        
        channel.flush()
        try await channel.close(mode: .all)
        
        self.channel = nil
    }
    
    func connect(
        username: String?,
        password: String?,
        version: String = "1.2",
        heartbeat: StompHeartbeat?,
        headers: StompHeaderDictionary
    ) async throws {
        isInStartupLoop = true
        defer { isInStartupLoop = false }
        
        try await Task.retrying {
            try await self.start()
        }.value
        
        var headers = headers.adding([
            .acceptVersion: version,
            .login: username,
            .passcode: password,
        ])
        
        if let heartbeat = heartbeat {
            headers[.heartbeat] = "\(heartbeat.send),\(heartbeat.receive)"
        }
        
        try await send(frame: .init(command: .CONNECT, headers: headers, body: nil))
    }
    
    func send(frame: StompClientFrame) async throws {
        guard let channel = channel else {
            throw StompError.notConnected
        }
        
        try await channel.writeAndFlush(frame)
    }
    
    func recoverConnection() {
        guard isInStartupLoop == false else {
            return
        }
        isInStartupLoop = true
        
        Task.detached {
            defer { self.isInStartupLoop = false }
            
            try await Task.retrying {
                try await self.start()
            }.value
            
            self.commandable.stomp.delegate?.didReconnect(client: self.commandable.stomp)
        }
    }
}
