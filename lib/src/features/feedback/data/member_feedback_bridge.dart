import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/appwrite/appwrite_config.dart';

/// Appwrite function that files a stored note. Public id, not a secret.
const feedbackForwardFunctionId = 'feedback-forward';

/// How long the app waits for the function to create the GitHub issue.
const memberFeedbackForwardTimeout = Duration(seconds: 12);

/// Asks [feedback-forward] to file `member_feedback/{feedbackId}`.
///
/// Returns null when the member is signed out, Appwrite is not configured,
/// or the function does not return an issue number. The Firestore note stays
/// either way. This function never reads `FEEDBACK_GITHUB_PAT`.
typedef MemberFeedbackForward = Future<({int number, String htmlUrl})?> Function(String feedbackId);

/// Production caller. Tests pass a [MemberFeedbackForward] instead.
Future<({int number, String htmlUrl})?> forwardMemberFeedback(String feedbackId) =>
    AppwriteMemberFeedbackBridge().forward(feedbackId);

/// Signed-in Firebase uid, or null when Firebase is not running.
String? readCurrentMemberId() {
  try {
    if (Firebase.apps.isEmpty) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return uid;
  } catch (_) {
    return null;
  }
}

Future<String?> readFirebaseIdToken() async {
  try {
    if (Firebase.apps.isEmpty) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return null;
    return token;
  } catch (_) {
    return null;
  }
}

/// HTTP client for the feedback-forward execution.
class AppwriteMemberFeedbackBridge {
  AppwriteMemberFeedbackBridge({
    http.Client? httpClient,
    AppwriteConfig? config,
    Future<String?> Function()? idTokenReader,
    Duration? timeout,
    this.functionId = feedbackForwardFunctionId,
  }) : _client = httpClient ?? http.Client(),
       _config = config ?? AppwriteConfig.fromEnvironment,
       _idTokenReader = idTokenReader ?? readFirebaseIdToken,
       timeout = timeout ?? memberFeedbackForwardTimeout;

  final http.Client _client;
  final AppwriteConfig _config;
  final Future<String?> Function() _idTokenReader;
  final Duration timeout;
  final String functionId;

  Future<({int number, String htmlUrl})?> forward(String feedbackId) async {
    final id = feedbackId.trim();
    if (id.isEmpty || !_config.isConfigured) return null;
    try {
      final idToken = await _idTokenReader();
      if (idToken == null || idToken.isEmpty) return null;
      final url = Uri.parse('${_config.endpoint.trim()}/functions/$functionId/executions');
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-Appwrite-Project': _config.projectId.trim(),
            },
            body: jsonEncode({
              'body': jsonEncode({'feedbackId': id, 'idToken': idToken}),
              'async': false,
            }),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      return parseMemberFeedbackForwardResponse(decoded);
    } catch (error) {
      debugPrint('feedback-forward request failed: ${error.runtimeType}');
      return null;
    }
  }
}

/// Reads an Appwrite execution body, or the function JSON itself.
({int number, String htmlUrl})? parseMemberFeedbackForwardResponse(Object? decoded) {
  if (decoded is! Map) return null;
  final status = decoded['responseStatusCode'];
  if (status != null) {
    final code = status is int ? status : int.tryParse('$status');
    if (code != 200) return null;
  }
  final raw = decoded.containsKey('responseBody') ? decoded['responseBody'] : decoded;
  if (raw is Map) return _issueFromMap(raw);
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final inner = jsonDecode(raw);
      if (inner is Map) return _issueFromMap(inner);
    } catch (_) {
      return null;
    }
  }
  return null;
}

({int number, String htmlUrl})? _issueFromMap(Map<dynamic, dynamic> json) {
  if (json['forwarded'] == false) return null;
  final number = _asInt(json['githubIssueNumber']);
  if (number == null || number <= 0) return null;
  final url = json['githubIssueUrl'];
  final htmlUrl = url is String && url.trim().isNotEmpty
      ? url.trim()
      : 'https://github.com/neiljaywarner/belong_feedback/issues/$number';
  return (number: number, htmlUrl: htmlUrl);
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
