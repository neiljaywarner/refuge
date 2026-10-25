import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/appwrite/appwrite_client_factory.dart';
import 'package:refuge4serverpod/src/core/appwrite/appwrite_config.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProvider, (call) async => '.');

  test('default config uses Appwrite and does not select Serverpod', () {
    expect(AppwriteConfig.fromEnvironment.isConfigured, isTrue);
    expect(
      AppwriteConfig.fromEnvironment.endpoint,
      AppwriteConfig.belongEndpoint,
    );
    expect(
      AppwriteConfig.fromEnvironment.projectId,
      AppwriteConfig.belongProjectId,
    );
    final services = createAppwriteServices(AppwriteConfig.fromEnvironment);
    expect(services, isNotNull);
    expect(services!.tables, isNotNull);
    expect(configuredBackendMode, BackendMode.appwrite);
    expect(PostRepositoryFactory.create(), isA<AppwritePostRepository>());
  });

  test('https without a host is not treated as configured', () {
    const config = AppwriteConfig(
      endpoint: 'https://',
      projectId: 'belong-dev',
    );
    expect(config.isConfigured, isFalse);
    expect(createAppwriteServices(config), isNull);
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
    expect(services.tables, isNotNull);
    expect(services.realtime, isNotNull);
    expect(services.account, isNotNull);
  });
}
