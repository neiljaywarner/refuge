import 'local_post_repository.dart';
import 'post_repository.dart';
import 'serverpod_post_repository.dart';

/// Backend runtime environment determined via --dart-define=BACKEND=...
enum BackendMode { local, serverpod, sqlite }

BackendMode get configuredBackendMode {
  const backend = String.fromEnvironment('BACKEND', defaultValue: 'local');
  switch (backend.toLowerCase()) {
    case 'serverpod':
      return BackendMode.serverpod;
    case 'sqlite':
    case 'postgres':
    case 'docker':
      return BackendMode.sqlite;
    case 'local':
    default:
      return BackendMode.local;
  }
}

class PostRepositoryFactory {
  static PostRepository create() {
    final mode = configuredBackendMode;
    switch (mode) {
      case BackendMode.serverpod:
        return ServerpodPostRepository();
      case BackendMode.sqlite:
      case BackendMode.local:
        return LocalPostRepository();
    }
  }
}
