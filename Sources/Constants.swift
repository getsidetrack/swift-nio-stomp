//
// Constants.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import Foundation
import Metrics

let NULL_BYTE: UInt8 = 0x00
let LINEFEED_BYTE: UInt8 = 0x0A
let COLON_BYTE: UInt8 = 0x3A
let SPACE_BYTE: UInt8 = 0x20

let LABEL_PREFIX: String = "com.getsidetrack.stomp"

let frameCounter = Counter(label: "stomp_frames_processed")
let frameErrorCounter = Counter(label: "stomp_frames_processed_errors")
let connectionCounter = Counter(label: "stomp_connection_count")
