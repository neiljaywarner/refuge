# ADR 0002: Abstract Repository Pattern Decoupling

## Status
Accepted

## Context
The application is being developed as a high-fidelity prototype that must run standalone offline during Phase 1 testing, but migrate seamlessly to the retired backend WebSocket streaming and PostgreSQL persistence during Phase 2 hackathon development.

Tightly coupling Flutter widgets directly to local state, SQLite, or Firebase client calls would cause fragile refactoring and break existing tests upon migration.

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
- `BACKEND=appwrite` (the default): Instantiates `AppwritePostRepository`, which also keeps a Cloud Firestore copy.

## Consequences
- **Positive**: 100% test isolation; widget tests do not need a running server or database. The UI talks to `PostRepository`, not to a client SDK.
- **Trade-off**: Local fixtures and the Firestore document shape still have to stay in step.
