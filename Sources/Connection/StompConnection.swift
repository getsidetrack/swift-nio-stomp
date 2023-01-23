//
// StompConnection.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
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
    }
    
    let handler = StompHandler()
    var channel: Channel?
    
    private func start() async throws {
        handler.communication = communication
        
        print("starting")
        let bootstrap = ClientBootstrap(group: eventLoopGroup)
//            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
//            .channelOption(ChannelOptions.socketOption(.so_keepalive), value: 1)
//            .channelOption(ChannelOptions.socketOption(.tcp_nodelay), value: 1)
            .channelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .channelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
            .channelOption(ChannelOptions.connectTimeout, value: TimeAmount.seconds(8))
            .channelInitializer {
                print("channelInitializer called")
                return $0.pipeline.addHandlers([
                    MessageToByteHandler(StompFrameEncoder()),
                    ByteToMessageHandler(StompFrameDecoder(executable: self.commandable)),
                    self.handler,
                ])
            }
        
        print("created bootstrap \(bootstrap)")
        channel = try await bootstrap.connect(host: host, port: port).get()
        print("connected")
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
        try await start()
        
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
}
