//
// StompHeaders.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

@dynamicMemberLookup
public struct StompHeaders {
    let lookup: StompHeaderDictionary
    
    public subscript(dynamicMember member: StompHeaderKey) -> String? {
        lookup[member] ?? nil
    }
    
    public var allValues: StompHeaderDictionary {
        lookup
    }

    public init(headers: StompHeaderDictionary) {
        self.lookup = headers
    }
}

public typealias StompHeaderDictionary = [StompHeaderKey: String?]
