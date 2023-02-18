//
// AsyncTimeout.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import Logging

struct TimedOutError: Error, Equatable {}

/// Execute an operation in the current task subject to a timeout.
///
/// - Parameters:
///   - seconds: The duration in seconds `operation` is allowed to run before timing out.
///   - operation: The async operation to perform.
/// - Returns: Returns the result of `operation` if it completed in time.
/// - Throws: Throws ``TimedOutError`` if the timeout expires before `operation` completes.
///   If `operation` throws an error before the timeout expires, that error is propagated to the caller.
func withTimeout<R>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> R
) async throws -> R {
    // sourced from: https://forums.swift.org/t/running-an-async-task-with-a-timeout/49733/13
    try await withThrowingTaskGroup(of: R.self) { group in
        let deadline = Date(timeIntervalSinceNow: seconds)

        // Start actual work.
        group.addTask {
            try await operation()
        }
        // Start timeout child task.
        group.addTask {
            let interval = deadline.timeIntervalSinceNow
            if interval > 0 {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            try Task.checkCancellation()
            // We’ve reached the timeout.
            throw TimedOutError()
        }
        // First finished child task wins, cancel the other task.
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

extension Task where Failure == Error {
    // adapted from: https://www.swiftbysundell.com/articles/retrying-an-async-swift-task/
    @discardableResult
    static func retrying(
        priority: TaskPriority? = nil,
        maxRetryCount: Int = .max,
        retryDelay _: TimeInterval = 1,
        operation: @escaping @Sendable () async throws -> Success
    ) async throws -> Task {
        let logger = Logger(label: LABEL_PREFIX + ".retrying")
        
        return Task(priority: priority) {
            for i in 0 ..< maxRetryCount {
                do {
                    logger.debug("attempt \(i) at operation")
                    return try await operation()
                } catch {
                    let delay = getDelay(for: i) * 1_000_000 // to nanoseconds
                    
                    logger.error("\(error)", metadata: [
                        "retryIndex": .stringConvertible(i),
                        "delay": .stringConvertible(delay),
                    ])
                    
                    try await Task<Never, Never>.sleep(nanoseconds: UInt64(delay))
                }
            }
            
            try Task<Never, Never>.checkCancellation()
            return try await operation()
        }
    }
    
    static func getDelay(for n: Int) -> Int {
        let maxDelay = 300_000 // 5 minutes
        let delay = Int(pow(2.0, Double(n))) * 1000
        let jitter = Int.random(in: 0 ... 1000)
        return min(delay + jitter, maxDelay)
    }
}
