import '../../../core/config/app_flavor.dart';
import 'local_post_repository.dart';
import 'post_repository.dart';
import 'serverpod_post_repository.dart';

/// Backend runtime environment determined via --dart-define=BACKEND=...
/// or toggled via --dart-define=ENABLE_SERVERPOD=false.
enum BackendMode { local, serverpod, sqlite, appwrite }

BackendMode get configuredBackendMode {
  const enableServerpod = bool.fromEnvironment('ENABLE_SERVERPOD', defaultValue: true);
  if (!enableServerpod) {
    return BackendMode.local;
  }
  const backend = String.fromEnvironment('BACKEND', defaultValue: 'serverpod');
  return switch (backend.toLowerCase()) {
    'local' => BackendMode.local,
    'sqlite' || 'postgres' || 'docker' => BackendMode.sqlite,
    'appwrite' => BackendMode.appwrite,
    _ => BackendMode.serverpod,
  };
}

class PostRepositoryFactory {
  static PostRepository create({AppFlavor flavor = AppFlavor.dev}) {
    final isDevMode = !flavor.isProduction;
    return switch (configuredBackendMode) {
      BackendMode.serverpod => ServerpodPostRepository(isDevMode: isDevMode),
      BackendMode.sqlite || BackendMode.local || BackendMode.appwrite => LocalPostRepository(
        isDevMode: isDevMode,
      ),
    };
  }
}
