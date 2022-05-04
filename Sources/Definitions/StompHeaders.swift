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
        lookup[member]
    }
    
    public var allValues: StompHeaderDictionary {
        lookup
    }
}

public typealias StompHeaderDictionary = [StompHeaderKey: String]
