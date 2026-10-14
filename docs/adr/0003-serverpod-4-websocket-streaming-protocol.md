# ADR 0003: Serverpod 4 WebSocket Streaming Protocol

## Status
Accepted

## Context
Real-time reflection updates are necessary for multi-member fellowship. Traditional REST polling creates unnecessary network traffic, latency, and battery drain on mobile devices.

Serverpod 4 provides native streaming endpoints backed by WebSockets and Redis message streams (`session.messages.postMessage`), perfectly tailored for room-isolated event delivery.

## Decision
1. Define the `Post` model in `serverpod_scaffold/protocol/post.spy.yaml`.
2. Implement `PostEndpoint.streamPosts(session, {required String spaceKey})` using Serverpod's `session.messages.createStream<Post>('space_$spaceKey')`.
3. Broadcast new posts and reaction updates to the space stream upon creation.
4. On the client, `ServerpodPostRepository` maps the incoming WebSocket stream directly into the UI's reactive `StreamBuilder`.

## Consequences
- **Positive**: Sub-second latency for live fellowship reflections; room-level stream isolation prevents broadcasting irrelevant posts to other spaces.
- **Trade-off**: Requires running PostgreSQL 16 and Redis 7 (now orchestrated via Docker Compose).
