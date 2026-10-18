import 'package:sanctuary_server_client/sanctuary_server_client.dart';

void main() async {
  final client = Client('https://refuge4serverpod.api.serverpod.space/');
  print('Testing connection to Serverpod Cloud...');
  try {
    final digest = await client.reflection.getQuietDigest('prayer_care');
    print('Digest received: ${digest.summaryMessage} (Reflections: ${digest.totalReflections}, Affirmations: ${digest.totalCareAffirmations})');
    
    print('Testing watchSpace stream directly...');
    final sub = client.reflection.watchSpace('prayer_care').listen(
      (post) => print('WatchSpace received post: "${post.content}" by ${post.authorName} (id: ${post.id})'),
      onError: (e) => print('WatchSpace error: $e'),
      onDone: () => print('WatchSpace done'),
    );
    
    print('Waiting 5 seconds to receive initial stream seeds...');
    await Future.delayed(const Duration(seconds: 5));
    await sub.cancel();
    client.close();
    print('TEST COMPLETED SUCCESSFULLY!');
  } catch (e, st) {
    print('Error: $e\n$st');
  }
}
