//
// StompHeaderKey.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

public enum StompHeaderKey: Hashable, CustomStringConvertible, ExpressibleByStringLiteral, Equatable {
    case contentLength
    case contentType
    case ack
    case transaction
    case id
    case receipt
    case receiptId
    case destination
    case acceptVersion
    case heartbeat
    case login
    case passcode
    case subscription
    case session
    case messageId
    
    case custom(String)
    
    static var allCases: [StompHeaderKey] = [
        .contentLength, .contentType, .ack, .transaction, .id, .receipt, .receiptId,
        .destination, .acceptVersion, .heartbeat, .login, .passcode, .subscription, .session,
        .messageId
    ]
    
    // MARK: - Public
    
    public init(stringLiteral value: String) {
        self.init(value: value)
    }

    public init(value: String) {
        let key = value.trimmingCharacters(in: .whitespacesAndNewlines)
        self = Self.allCases.first(where: { $0.key == value }) ?? .custom(key)
    }
    
    public var description: String {
        key
    }
    
    // MARK: - Internal
    
    var key: String {
        switch self {
        case .contentLength:
            return "content-length"
        case .contentType:
            return "content-type"
        case .ack:
            return "ack"
        case .transaction:
            return "transaction"
        case .id:
            return "id"
        case .receipt:
            return "receipt"
        case .receiptId:
            return "receipt-id"
        case .destination:
            return "destination"
        case .acceptVersion:
            return "accept-version"
        case .heartbeat:
            return "heart-beat"
        case .login:
            return "login"
        case .passcode:
            return "passcode"
        case .subscription:
            return "subscription"
        case .session:
            return "session"
        case .messageId:
            return "message-id"
        case .custom(let value):
            return value
        }
    }
    
    public static func == (lhs: StompHeaderKey, rhs: StompHeaderKey) -> Bool {
        lhs.key == rhs.key
    }
}
