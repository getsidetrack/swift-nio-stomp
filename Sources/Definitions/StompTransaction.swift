//
// StompTransaction.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation

public enum StompTransactionResult {
    /// COMMIT is used to commit a transaction in progress.
    case commit
    
    /// ABORT is used to roll back a transaction in progress.
    case abort
}
