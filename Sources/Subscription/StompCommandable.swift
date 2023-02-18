//
// StompCommandable.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

public protocol StompCommandable {
    var stomp: StompExecutable { get }
    var transactionName: String? { get }
    var subscriptionId: String? { get }
}

struct StompSubscription: StompCommandable {
    let stomp: StompExecutable
    let transactionName: String? = nil
    let subscriptionId: String?
}

struct StompTransaction: StompCommandable {
    let stomp: StompExecutable
    let transactionName: String?
    let subscriptionId: String?
    
    init(transactionName: String, subscriptionId: String, stomp: StompExecutable) {
        self.transactionName = transactionName
        self.subscriptionId = subscriptionId
        self.stomp = stomp
    }
}

public protocol StompExecutable {
    func subscribe(destination: String, id: String?, ack: StompAckMode, headers: StompHeaderDictionary, onMessage closure: @escaping StompMessageCallback) async throws -> StompCommandable
    func cleanupSubscription(id: String)
    func send(command: StompCommand, headers: StompHeaderDictionary, body: Data?) async throws
    func disconnect() async throws
}
