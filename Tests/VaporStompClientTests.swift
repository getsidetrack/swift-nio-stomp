//
// VaporStompClientTests.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import NIOCore
import NIOPosix
@testable import NIOSTOMP
import XCTest

final class VaporStompClientTests: XCTestCase {
    func testExample() throws {
        // TODO:
    }
}

final class TempTests: XCTestCase {
    func testHeaders() throws {
        let stomp = StubStompExecutable()
        let transaction = StompTransaction(transactionName: "transaction", subscriptionId: "", stomp: stomp)
        
        XCTAssertEqual(
            transaction.baseHeaders.adding([ .id: "two" ]),
            [
                .transaction: "transaction",
                .id: "two",
            ]
        )
        
        XCTAssertEqual(
            transaction.baseHeaders.adding([ .transaction: "transaction-two" ]),
            [
                .transaction: "transaction",
            ]
        )
        
        let subscription = StompSubscription(stomp: stomp, subscriptionId: "")
        
        XCTAssertEqual(
            subscription.baseHeaders.adding([ .transaction: "transaction-two" ]),
            [
                .transaction: "transaction-two",
            ]
        )
    }
}

struct StubStompExecutable: StompExecutable {
    func send(command _: StompCommand, headers _: StompHeaderDictionary, body _: Data?) async throws {}
    
    func disconnect() async throws {}
}
