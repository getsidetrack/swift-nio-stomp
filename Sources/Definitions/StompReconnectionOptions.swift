//
// StompReconnectionOptions.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

public struct StompReconnectionOptions {
    public let enabled: Bool
    
    public static var disabled: StompReconnectionOptions {
        .init(enabled: false)
    }
}
