//
// StompHandler.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

import CoreMetrics
import Foundation
import Logging
import NIOCore

typealias STOMPMessageReceived = (StompFrame) -> Void
typealias STOMPErrorCaught = (Error) -> Void

final class StompHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = StompFrame
    typealias OutboundOut = StompClientFrame
    
    private let logger = Logger(label: LABEL_PREFIX + ".handler")
    
    var communication: StompCommunication?
    weak var connection: StompConnection?
    
    func channelRead(context _: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        communication?.onFrame(frame)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("received error from connection: \(error)")
        
        context.close(promise: nil)
        communication?.onError(error)
    }
    
    // MARK: - Telemetry
    
    func channelActive(context: ChannelHandlerContext) {
        getMetric(forContext: context).record(1)
        logger.info("client connected to \(context.remoteAddress?.description ?? "unknown address!")")
    }
    
    func handlerRemoved(context: ChannelHandlerContext) {
        getMetric(forContext: context).record(0)
        logger.debug("handler was removed \(context.name)")
        connection?.recoverConnection()
    }
    
    func getMetric(forContext context: ChannelHandlerContext) -> Gauge {
        Gauge(label: "stomp_connection_status", dimensions: [
            ("address", context.remoteAddress?.description ?? ""),
            ("name", context.name),
        ])
    }
}
