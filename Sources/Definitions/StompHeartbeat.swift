//
// StompHeartbeat.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

public struct StompHeartbeat {
    public let send: Int
    public let receive: Int
    
    public init(send: Int, receive: Int) {
        self.send = send
        self.receive = receive
    }
}
