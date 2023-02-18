//
// LoggerError.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import Logging

extension Logger {
    /// Reports an `Error` to this `Logger`.
    ///
    /// - parameters:
    ///     - error: `Error` to log.
    func report(
        error: Error,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        let source: ErrorSource?
        let reason: String
        let level: Logger.Level
        switch error {
        case let localized as LocalizedError:
            reason = localized.localizedDescription
            source = nil
            level = .warning
        case let convertible as CustomStringConvertible:
            reason = convertible.description
            source = nil
            level = .warning
        default:
            reason = "\(error)"
            source = nil
            level = .warning
        }
        
        self.log(
            level: level,
            .init(stringLiteral: reason),
            file: source?.file ?? file,
            function: source?.function ?? function,
            line: numericCast(source?.line ?? line)
        )
    }
}

/// A source-code location.
struct ErrorSource {
    /// File in which this location exists.
    var file: String

    /// Function in which this location exists.
    var function: String

    /// Line number this location belongs to.
    var line: UInt

    /// Number of characters into the line this location starts at.
    var column: UInt

    /// Optional start/end range of the source.
    var range: Range<UInt>?

    /// Creates a new `SourceLocation`
    init(
        file: String,
        function: String,
        line: UInt,
        column: UInt,
        range: Range<UInt>? = nil
    ) {
        self.file = file
        self.function = function
        self.line = line
        self.column = column
        self.range = range
    }
}

extension ErrorSource {
    /// Creates a new `ErrorSource` for the current call site.
    static func capture(
        file: String = #file,
        function: String = #function,
        line: UInt = #line,
        column: UInt = #column,
        range: Range<UInt>? = nil
    ) -> Self {
        return self.init(
            file: file,
            function: function,
            line: line,
            column: column,
            range: range
        )
    }
}
