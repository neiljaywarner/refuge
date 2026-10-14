import 'package:sanctuary_server_client/sanctuary_server_client.dart';

void main() async {
  final client = Client('https://refuge4serverpod.api.serverpod.space/');
  try {
    print('Testing connection to Serverpod Cloud API...');
    final digest = await client.reflection.getQuietDigest('prayer_care');
    print('SUCCESS: Received digest: $digest');

    final post = ReflectionPost(
      authorName: 'Neil & Sanctuary Team',
      spaceKey: 'main_hall',
      intentTag: '[Care]',
      specialInterestTag: 'Psalm 139:14',
      content: 'Cloud verification test on refuge4serverpod',
      createdAt: DateTime.now().toUtc(),
      prayingCount: 0,
      standingWithCount: 0,
      peaceCount: 0,
      encouragedCount: 1,
    );
    final published = await client.reflection.publishReflection(post);
    print('SUCCESS: Published post with ID: ${published.id}');
  } catch (e, st) {
    print('ERROR: $e');
    print(st);
  }
}
