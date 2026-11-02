import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:refuge4serverpod/src/core/appwrite/appwrite_client_factory.dart';
import 'package:refuge4serverpod/src/core/appwrite/appwrite_config.dart';
import 'package:refuge4serverpod/src/features/reflections/data/appwrite_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

import '../../support/http_cassette.dart';

bool _hasJsonBody(List<int> body, ContentType contentType) =>
    body.isNotEmpty && contentType.mimeType == 'application/json';

class _FakePaths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async => Directory.systemTemp.path;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

bool _isRowsList(Uri uri) =>
    uri.path.endsWith('/tables/reflection_posts/rows') && !uri.path.endsWith('/post-100');

/// TablesDB cassette for [AppwriteReflectionMirror].
///
/// The Appwrite SDK builds its own `HttpClient`. Nock is installed first, so
/// `listRows`, `updateRow`, and `createRow` never leave the test process.
void main() {
  const endpoint = AppwriteConfig.belongEndpoint;
  const config = AppwriteConfig(endpoint: endpoint, projectId: AppwriteConfig.belongProjectId);
  const rowsPath = '/tablesdb/belong_community_db/tables/reflection_posts/rows';

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = _FakePaths();
    nock.init();
  });

  setUp(nock.cleanAll);

  tearDownAll(() {
    nock.cleanAll();
    HttpOverrides.global = null;
  });

  AppwriteReflectionMirror mirror() {
    final services = createAppwriteServices(config);
    expect(services, isNotNull);
    return AppwriteReflectionMirror(services!, config);
  }

  Post quietNote() => Post(
    id: 'post-100',
    authorName: 'Fellow Member',
    spaceKey: 'prayer',
    toneTag: '[Support]',
    content: 'A quiet note from the cassette.',
    timestamp: DateTime.utc(2026, 10, 24, 12),
    reactions: const {'pray': 1, 'encouraged': 2},
  );

  test('lists reflection rows from a TablesDB cassette', () async {
    nock(endpoint)
        .get(_isRowsList)
        .reply(
          200,
          loadHttpFixture('appwrite/tablesdb_rows_list.json'),
          headers: {'content-type': 'application/json'},
        );

    final posts = await mirror().listPosts(spaceKey: 'prayer');

    expect(posts, hasLength(1));
    expect(posts.single.id, 'post-100');
    expect(posts.single.content, 'A quiet note from the cassette.');
    expect(posts.single.reactions['pray'], 1);
    expect(posts.single.reactions['encouraged'], 2);
    expect(posts.single.reactions['relatable'], 2);
    expect(nock.pendingMocks, isEmpty);
  });

  test('a missing row cassette is followed by createRow', () async {
    nock(endpoint)
        .patch('$rowsPath/post-100', _hasJsonBody)
        .reply(
          404,
          loadHttpFixture('appwrite/tablesdb_row_missing.json'),
          headers: {'content-type': 'application/json'},
        );
    nock(endpoint)
        .post(rowsPath, _hasJsonBody)
        .reply(
          201,
          loadHttpFixture('appwrite/tablesdb_row_created.json'),
          headers: {'content-type': 'application/json'},
        );

    await mirror().upsertPost(quietNote());

    expect(nock.pendingMocks, isEmpty);
  });
}
