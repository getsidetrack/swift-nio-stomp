//
// StompCommand.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

public enum StompCommand: String {
    // Client Commands (Send)
    case ABORT
    case ACK
    case BEGIN
    case COMMIT
    case CONNECT
    case DISCONNECT
    case NACK
    case SEND
    case SUBSCRIBE
    case UNSUBSCRIBE
    
    // Server Commands (Receive)
    case CONNECTED
    case ERROR
    case MESSAGE
    case RECEIPT
}
