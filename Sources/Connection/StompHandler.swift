//
// StompHandler.swift
//
// Copyright 2022 • Sidetrack Tech Limited
//

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
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        communication?.onFrame(frame)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("received error from connection: \(error.localizedDescription)")
        
        context.close(promise: nil)
        communication?.onError(error)
    }
    
    // MARK: - Telemetry
    
    func channelActive(context: ChannelHandlerContext) {
        logger.debug("client connected to \(context.remoteAddress?.description ?? "unknown address!")")
    }
    
    func handlerRemoved(context _: ChannelHandlerContext) {
        logger.debug("handler was removed")
    }
}
