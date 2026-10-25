import 'dart:convert';
import 'dart:io';

const _apiKey = 'AIzaSyBtW8uQckI88rT1TPng459EVC9ynnm2twU';
const _projectId = 'belongonthespectrum';

class TestUser {
  final String email;
  final String password;
  final String displayName;
  String idToken = '';
  String localId = '';

  TestUser({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

Future<void> main() async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  stdout.writeln('=== Two-Device Live Smoke Test: Belong on the Spectrum ===');
  stdout.writeln('Timestamp: $timestamp');

  final client = HttpClient();

  // 1. Create User 1 (Alice - Dallas)
  final user1 = TestUser(
    email: 'alice_smoke_$timestamp@belongonthespectrum.com',
    password: 'Password123!',
    displayName: 'Alice (Dallas)',
  );

  // 2. Create User 2 (Bob - Fort Worth)
  final user2 = TestUser(
    email: 'bob_smoke_$timestamp@belongonthespectrum.com',
    password: 'Password123!',
    displayName: 'Bob (Fort Worth)',
  );

  stdout.writeln('\n1. Registering User 1: ${user1.email}...');
  await _signUpUser(client, user1);
  stdout.writeln('   User 1 UID: ${user1.localId} (Registered successfully)');

  stdout.writeln('\n2. Registering User 2: ${user2.email}...');
  await _signUpUser(client, user2);
  stdout.writeln('   User 2 UID: ${user2.localId} (Registered successfully)');

  // 3. User 1 posts top-level comment under Post 1
  final comment1Id = 'smoke_comment_1_$timestamp';
  stdout.writeln(
    '\n3. User 1 (${user1.displayName}) posting top-level comment to Firestore...',
  );
  final comment1Data = {
    'postId': {'stringValue': '1'},
    'authorName': {'stringValue': user1.displayName},
    'content': {
      'stringValue': 'Grace and peace to everyone in Belong on the Spectrum. Remembering Psalm 139:14 today.',
    },
    'toneTag': {'stringValue': '[Prayer]'},
    'timestamp': {'stringValue': DateTime.now().toUtc().toIso8601String()},
    'reactions': {
      'mapValue': {
        'fields': {
          'pray': {'integerValue': '1'},
        },
      },
    },
  };
  await _writeFirestoreDoc(
    client,
    user1.idToken,
    'comments',
    comment1Id,
    comment1Data,
  );
  stdout.writeln(
    '   Top-level comment created in Firestore with ID: $comment1Id',
  );

  // 4. User 2 posts nested reply to User 1's comment
  final comment2Id = 'smoke_comment_2_reply_$timestamp';
  stdout.writeln(
    '\n4. User 2 (${user2.displayName}) posting nested reply to comment $comment1Id...',
  );
  final comment2Data = {
    'postId': {'stringValue': '1'},
    'parentCommentId': {'stringValue': comment1Id},
    'authorName': {'stringValue': user2.displayName},
    'content': {
      'stringValue': 'Amen Alice! That scripture is so grounding for autistic disciples. Holding space with you.',
    },
    'toneTag': {'stringValue': '[Comfort Only]'},
    'timestamp': {'stringValue': DateTime.now().toUtc().toIso8601String()},
    'reactions': {
      'mapValue': {
        'fields': {
          'peace': {'integerValue': '2'},
        },
      },
    },
  };
  await _writeFirestoreDoc(
    client,
    user2.idToken,
    'comments',
    comment2Id,
    comment2Data,
  );
  stdout.writeln(
    '   Nested reply created in Firestore with ID: $comment2Id (parentCommentId: $comment1Id)',
  );

  // 5. Query and verify both comments from Firestore
  stdout.writeln('\n5. Verifying nested comments from Firestore REST API...');
  final retrieved1 = await _readFirestoreDoc(client, 'comments', comment1Id);
  final retrieved2 = await _readFirestoreDoc(client, 'comments', comment2Id);

  stdout.writeln(
    '   Parent comment content: ${retrieved1['fields']?['content']?['stringValue']}',
  );
  stdout.writeln(
    '   Reply comment content:  ${retrieved2['fields']?['content']?['stringValue']}',
  );
  stdout.writeln(
    '   Reply parentCommentId:  ${retrieved2['fields']?['parentCommentId']?['stringValue']}',
  );

  if (retrieved2['fields']?['parentCommentId']?['stringValue'] == comment1Id) {
    stdout.writeln(
      '\n SUCCESS: Verified two-device registration & live nested comments in Cloud Firestore!',
    );
    stdout.writeln('   Parent ID: $comment1Id');
    stdout.writeln('   Nested Child ID: $comment2Id');
    stdout.writeln(
      '   Hierarchy: User 1 (${user1.displayName}) -> User 2 (${user2.displayName})',
    );
  } else {
    stderr.writeln('❌ Nested relationship mismatch!');
    exit(1);
  }

  client.close();
}

Future<void> _signUpUser(HttpClient client, TestUser user) async {
  final url = Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
  );
  final request = await client.postUrl(url);
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({
      'email': user.email,
      'password': user.password,
      'returnSecureToken': true,
    }),
  );
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw Exception('Failed to sign up ${user.email}: $body');
  }
  final json = jsonDecode(body) as Map<String, dynamic>;
  user.idToken = json['idToken'] as String;
  user.localId = json['localId'] as String;

  // Set Display Name
  final updateUrl = Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$_apiKey',
  );
  final updateReq = await client.postUrl(updateUrl);
  updateReq.headers.contentType = ContentType.json;
  updateReq.write(
    jsonEncode({
      'idToken': user.idToken,
      'displayName': user.displayName,
      'returnSecureToken': true,
    }),
  );
  final updateResp = await updateReq.close();
  await updateResp.drain();
}

Future<void> _writeFirestoreDoc(
  HttpClient client,
  String idToken,
  String collection,
  String docId,
  Map<String, dynamic> fields,
) async {
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$collection?documentId=$docId',
  );
  final request = await client.postUrl(url);
  request.headers.contentType = ContentType.json;
  request.headers.add('Authorization', 'Bearer $idToken');
  request.write(jsonEncode({'fields': fields}));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to write Firestore doc $docId: $body');
  }
}

Future<Map<String, dynamic>> _readFirestoreDoc(
  HttpClient client,
  String collection,
  String docId,
) async {
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$collection/$docId',
  );
  final request = await client.getUrl(url);
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw Exception('Failed to read Firestore doc $docId: $body');
  }
  return jsonDecode(body) as Map<String, dynamic>;
}
