import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../../../core/appwrite/appwrite_config.dart';
import '../domain/stored_direct_message.dart';

/// Appwrite function that copies one stored direct message. Public id, not a secret.
const directMessageMirrorFunctionId = 'dm-mirror';

/// One-way copy of a direct message. Firestore stays the copy the app reads.
///
/// The phone asks this mirror after Firestore accepts the write. It does not
/// hold an Appwrite API key and it does not write the table itself.
abstract class DirectMessageMirror {
  Future<void> copyMessage(StoredDirectMessage message);
}

/// Fields copied onto the spare row. Names match the Firestore document.
Map<String, Object?> directMessageMirrorFields(StoredDirectMessage message) => {
  'threadId': message.threadId,
  'senderId': message.senderId,
  'senderName': message.senderName,
  'recipientIds': message.recipientIds,
  'recipientNames': message.recipientNames,
  'participantIds': message.participantIds,
  'subject': message.subject ?? '',
  'content': message.content,
  'sentAt': message.sentAt.toIso8601String(),
};

/// Body posted to the function execution endpoint.
///
/// The message text stays in Firestore. The function reads it with the
/// sender's token. This map has no API key.
Map<String, Object?> directMessageMirrorExecutionBody({
  required String idToken,
  required String messageId,
}) => {
  'body': jsonEncode({'action': 'copy', 'idToken': idToken, 'messageId': messageId}),
  'async': false,
};

/// Asks `dm-mirror` to copy a message. A down function throws.
///
/// The caller catches that throw. The Firestore document is already stored.
class AppwriteFunctionDirectMessageMirror implements DirectMessageMirror {
  AppwriteFunctionDirectMessageMirror({
    http.Client? client,
    this.timeout = const Duration(seconds: 2),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  @override
  Future<void> copyMessage(StoredDirectMessage message) async {
    if (Firebase.apps.isEmpty) {
      throw StateError('direct message mirror skipped');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('direct message mirror skipped');
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('direct message mirror skipped');
    }
    final config = AppwriteConfig.fromEnvironment;
    if (!config.isConfigured) throw StateError('direct message mirror skipped');

    final url = Uri.parse(
      '${config.endpoint.trim()}/functions/$directMessageMirrorFunctionId/executions',
    );
    final response = await _client
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'X-Appwrite-Project': config.projectId.trim(),
          },
          body: jsonEncode(
            directMessageMirrorExecutionBody(idToken: idToken, messageId: message.id),
          ),
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('direct message mirror was not accepted');
    }
    final outer = jsonDecode(response.body);
    if (outer is! Map) return;
    final status = outer['responseStatusCode'];
    if (status is int && (status < 200 || status >= 300)) {
      throw StateError('direct message mirror was refused');
    }
    final responseBody = outer['responseBody'];
    if (responseBody is! String || responseBody.isEmpty) return;
    final inner = jsonDecode(responseBody);
    if (inner is Map && inner['mirrored'] == false) {
      throw StateError('direct message mirror did not copy');
    }
  }
}
