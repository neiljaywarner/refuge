import '../../../core/config/app_flavor.dart';
import 'appwrite_post_repository.dart';
import 'local_post_repository.dart';
import 'post_repository.dart';
import 'serverpod_post_repository.dart';

/// Backend selected with `--dart-define=BACKEND=...`.
///
/// The default is [BackendMode.appwrite]. That repository writes each
/// reflection to Appwrite and a second copy to Cloud Firestore, then falls
/// back to the local cache. Firebase Auth is unchanged.
///
/// Serverpod Cloud is contacted only when the build sets both
/// `BACKEND=serverpod` and `ENABLE_SERVERPOD=true`.
enum BackendMode { local, serverpod, sqlite, appwrite }

BackendMode get configuredBackendMode {
  const backend = String.fromEnvironment('BACKEND', defaultValue: 'appwrite');
  const enableServerpod = bool.fromEnvironment('ENABLE_SERVERPOD');
  return switch (backend.toLowerCase()) {
    'local' => BackendMode.local,
    'sqlite' || 'postgres' || 'docker' => BackendMode.sqlite,
    'serverpod' when enableServerpod => BackendMode.serverpod,
    _ => BackendMode.appwrite,
  };
}

class PostRepositoryFactory {
  static PostRepository create({AppFlavor flavor = AppFlavor.dev}) {
    final isDevMode = !flavor.isProduction;
    return switch (configuredBackendMode) {
      BackendMode.serverpod => ServerpodPostRepository(isDevMode: isDevMode),
      BackendMode.appwrite => AppwritePostRepository(isDevMode: isDevMode),
      BackendMode.sqlite ||
      BackendMode.local => LocalPostRepository(isDevMode: isDevMode),
    };
  }
}
