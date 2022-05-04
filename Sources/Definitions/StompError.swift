//
// StompError.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

enum StompError: Error {
    case missingAckId
    case missingSubscription
    case notConnected
}
