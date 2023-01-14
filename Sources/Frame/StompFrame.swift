//
// StompFrame.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

public final class StompFrame: StompClientFrame {
    private let executable: StompCommandable
    
    init(
        command: StompCommand,
        headers: StompHeaderDictionary,
        body: Data = Data(),
        executable: StompCommandable
    ) {
        self.executable = executable
        super.init(command: command, headers: headers, body: body)
    }
    
    public func ack(headers: StompHeaderDictionary = [:]) async throws {
        try await executable.ack(frame: self, headers: headers)
    }
    
    public func nack(headers: StompHeaderDictionary = [:]) async throws {
        try await executable.nack(frame: self, headers: headers)
    }
}

public class StompClientFrame {
    public let command: StompCommand
    public let headers: StompHeaders
    public let body: Data
    
    init(
        command: StompCommand,
        headers: StompHeaderDictionary,
        body: Data?
    ) {
        self.command = command
        self.headers = .init(headers: headers)
        self.body = body ?? Data()
    }
}
