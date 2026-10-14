import 'local_post_repository.dart';
import 'post_repository.dart';
import 'serverpod_post_repository.dart';

/// Backend runtime environment determined via --dart-define=BACKEND=...
enum BackendMode { local, serverpod, sqlite }

BackendMode get configuredBackendMode {
  const backend = String.fromEnvironment('BACKEND', defaultValue: 'serverpod');
  return switch (backend.toLowerCase()) {
    'local' => BackendMode.local,
    'sqlite' || 'postgres' || 'docker' => BackendMode.sqlite,
    _ => BackendMode.serverpod,
  };
}

class PostRepositoryFactory {
  static PostRepository create() => switch (configuredBackendMode) {
    BackendMode.serverpod => ServerpodPostRepository(),
    BackendMode.sqlite || BackendMode.local => LocalPostRepository(),
  };
}
