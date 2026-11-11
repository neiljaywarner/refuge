import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/prune_client_session_audits.dart';

void main() {
  test('a response that stalls after the headers fails inside the deadline', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) {
      request.response.statusCode = 200;
      request.response.write('{');
    });

    final store = AppwriteSessionAuditStore(
      endpoint: 'http://127.0.0.1:${server.port}/v1',
      projectId: 'proj',
      databaseId: 'belong_community_db',
      apiKey: 'test-key-not-a-real-secret',
      requestDeadline: const Duration(milliseconds: 200),
    );

    final started = DateTime.now();
    await expectLater(store.listRawSessions(), throwsA(isA<TimeoutException>()));
    expect(DateTime.now().difference(started), lessThan(const Duration(seconds: 2)));
  });
}
