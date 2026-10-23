import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/appwrite/appwrite_client_factory.dart';
import 'package:refuge4serverpod/src/core/appwrite/appwrite_config.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository_factory.dart';
import 'package:refuge4serverpod/src/features/reflections/data/serverpod_post_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProvider, (call) async => '.');

  test('default Appwrite config stays off so Serverpod remains the live backend', () {
    expect(AppwriteConfig.fromEnvironment.isConfigured, isFalse);
    expect(createAppwriteServices(AppwriteConfig.fromEnvironment), isNull);
    expect(configuredBackendMode, BackendMode.serverpod);
    expect(
      PostRepositoryFactory.create(),
      isA<ServerpodPostRepository>(),
    );
  });

  test('placeholder endpoint and project id are not treated as configured', () {
    const config = AppwriteConfig(
      endpoint: 'https://<REGION>.cloud.appwrite.io/v1',
      projectId: 'your-project-id',
    );
    expect(config.isConfigured, isFalse);
    expect(createAppwriteServices(config), isNull);
  });

  test('a real endpoint and project id can build an Appwrite client', () {
    const config = AppwriteConfig(
      endpoint: 'https://cloud.appwrite.io/v1',
      projectId: 'belong-dev',
      databaseId: 'belong_community_db',
    );
    expect(config.isConfigured, isTrue);
    final services = createAppwriteServices(config);
    expect(services, isNotNull);
    expect(services!.databases, isNotNull);
    expect(services.realtime, isNotNull);
    expect(services.account, isNotNull);
  });
}
