import '../../../core/config/app_flavor.dart';
import 'appwrite_post_repository.dart';
import 'local_post_repository.dart';
import 'post_repository.dart';

/// Backend selected with `--dart-define=BACKEND=...`.
///
/// The default is [BackendMode.appwrite]. That class reads and writes Cloud
/// Firestore (`reflections` in production, `reflections_dev` on the dev
/// site) and keeps the on-device list. It does not call the Appwrite table
/// `reflection_posts`. That table stays disabled (ADR-0011). Firebase Auth
/// is unchanged.
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
