import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository_factory.dart';
import 'package:refuge4serverpod/src/features/reflections/data/serverpod_post_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    pathProvider,
    (call) async => '.',
  );

  group('PostRepositoryFactory', () {
    test('creates repository instance matching configured backend mode', () {
      final repo = PostRepositoryFactory.create(flavor: AppFlavor.dev);

      switch (configuredBackendMode) {
        case BackendMode.serverpod:
          expect(repo, isA<ServerpodPostRepository>());
          expect((repo as ServerpodPostRepository).isDevMode, isTrue);
          break;
        case BackendMode.appwrite:
          expect(repo, isA<AppwritePostRepository>());
          expect((repo as AppwritePostRepository).isDevMode, isTrue);
          break;
        case BackendMode.local:
        case BackendMode.sqlite:
          expect(repo, isA<LocalPostRepository>());
          expect((repo as LocalPostRepository).isDevMode, isTrue);
          break;
      }
    });

    test('creates production repository instance matching configured mode', () {
      final repo = PostRepositoryFactory.create(flavor: AppFlavor.prod);

      switch (configuredBackendMode) {
        case BackendMode.serverpod:
          expect(repo, isA<ServerpodPostRepository>());
          expect((repo as ServerpodPostRepository).isDevMode, isFalse);
          break;
        case BackendMode.appwrite:
          expect(repo, isA<AppwritePostRepository>());
          expect((repo as AppwritePostRepository).isDevMode, isFalse);
          break;
        case BackendMode.local:
        case BackendMode.sqlite:
          expect(repo, isA<LocalPostRepository>());
          expect((repo as LocalPostRepository).isDevMode, isFalse);
          break;
      }
    });

    test('BackendMode enum contains all migration targets', () {
      expect(BackendMode.values, contains(BackendMode.local));
      expect(BackendMode.values, contains(BackendMode.serverpod));
      expect(BackendMode.values, contains(BackendMode.sqlite));
      expect(BackendMode.values, contains(BackendMode.appwrite));
    });
  });
}
