import '../../../core/config/app_flavor.dart';
import 'appwrite_post_repository.dart';
import 'local_post_repository.dart';
import 'post_repository.dart';

/// Backend selected with `--dart-define=BACKEND=...`.
///
/// The default is [BackendMode.appwrite]. That repository writes each
/// reflection to Appwrite and a second copy to Cloud Firestore, then falls
/// back to the local cache. Firebase Auth is unchanged.
///
/// Firestore (`reflections` in prod, `reflections_dev` in dev) stays the live
/// community store. There is no second cloud socket.
enum BackendMode { local, sqlite, appwrite }

BackendMode get configuredBackendMode {
  const backend = String.fromEnvironment('BACKEND', defaultValue: 'appwrite');
  return switch (backend.toLowerCase()) {
    'local' => BackendMode.local,
    'sqlite' || 'postgres' || 'docker' => BackendMode.sqlite,
    _ => BackendMode.appwrite,
  };
}

class PostRepositoryFactory {
  static PostRepository create({AppFlavor flavor = AppFlavor.dev}) {
    final isDevMode = !flavor.isProduction;
    return switch (configuredBackendMode) {
      BackendMode.appwrite => AppwritePostRepository(isDevMode: isDevMode),
      BackendMode.sqlite || BackendMode.local => LocalPostRepository(isDevMode: isDevMode),
    };
  }
}
