# SwiftNIO STOMP

⚠️ Work in progress. I do not recommend using this in your own applications (see information below).

Built on top of [NIO](https://github.com/apple/swift-nio/), this Swift package provides client-side compatibility with STOMP 1.0, 1.1 and 1.2 servers. It is designed to work well with server-side frameworks such as Vapor, for applications where you need to ingest data using the [STOMP protocol](http://stomp.github.io/index.html).

## Scope

While the project does work, there's a lot of room to improve (pull requests accepted!). Some areas which have been considered:

- Server compatibility: Act as a server, allowing clients to connect and send/receive messages.
- Improved resilience (Connection fallover, better error handling, automatic reconnections/resubscribe)
- Message batching, unbatching, transformers, and decoders.
- Improved observability using metrics, tracing and logging.
- SSL/TLS support.

## Known Issues and Incomplete Work

- There appears an unknown frame decoding issue affecting ~0.8% of messages causing the data to be incomplete.
- Receipts are currently unsupported.
- Add `client-auto` ack mode (`client-individual` but automatically acknowledged once successfully processed by this package)
- Add full suite of unit tests (including performance tests)
- Add integration test using mock STOMP broker
- Add full DocC documentation
