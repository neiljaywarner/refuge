# ADR 0002: Abstract Repository Pattern Decoupling

## Status
Accepted

## Context
The application is being developed as a high-fidelity prototype that must run standalone offline during Phase 1 testing, but migrate seamlessly to Serverpod 4 WebSocket streaming and PostgreSQL persistence during Phase 2 hackathon development.

Tightly coupling Flutter widgets directly to local state, SQLite, or Serverpod client calls would cause fragile refactoring and break existing tests upon migration.

## Decision
We decouple the UI layer entirely from persistence and networking through an abstract `PostRepository` contract:
```dart
abstract class PostRepository {
  Future<List<Post>> getPosts({required String spaceKey});
  Future<Post> createPost(Post post);
  Future<void> addReaction({required String postId, required String reactionType});
  Stream<List<Post>> watchPosts({required String spaceKey});
}
```
All UI widgets (`SanctuaryApp`, `SanctuaryHomeScreen`, `_buildPostList`) depend strictly on `PostRepository`.
Runtime selection is managed via `PostRepositoryFactory` driven by `--dart-define=BACKEND=...`:
- `BACKEND=local`: Instantiates `LocalPostRepository` (in-memory broadcast stream generator).
- `BACKEND=serverpod`: Instantiates `ServerpodPostRepository` (connecting to Serverpod streaming endpoint with automatic offline fallback).

## Consequences
- **Positive**: 100% test isolation; all widget tests execute in 3 seconds without needing a running server or database. Migration to Serverpod requires zero UI code modifications.
- **Trade-off**: Requires maintaining parity between local mock data models and Serverpod generated protocol entities.
