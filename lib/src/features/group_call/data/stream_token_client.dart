import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/stream_call_credentials.dart';

// Public constructor names stay httpClient and readIdToken.
// ignore_for_file: prefer_initializing_formals

class StreamTokenException implements Exception {
  const StreamTokenException(this.message);
  final String message;
}

/// Asks the preview function for a user token. The secret never leaves the function.
class StreamTokenClient {
  StreamTokenClient({
    required this.endpoint,
    required http.Client httpClient,
    required Future<String?> Function() readIdToken,
  }) : _httpClient = httpClient,
       _readIdToken = readIdToken;

  final Uri endpoint;
  final http.Client _httpClient;
  final Future<String?> Function() _readIdToken;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    _httpClient.close();
  }

  Future<StreamCallCredentials> mint({required String callId}) async {
    if (_closed) {
      throw const StreamTokenException('The call could not start. Try again in a moment.');
    }
    final idToken = await _readIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const StreamTokenException(
        'A Firebase sign-in is required to join. Guest mode cannot start a call.',
      );
    }
    final http.Response response;
    try {
      response = await _httpClient.post(
        endpoint,
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'callId': callId}),
      );
    } catch (_) {
      throw const StreamTokenException('The call could not start. Try again in a moment.');
    }
    if (response.statusCode == 401) {
      throw const StreamTokenException(
        'A Firebase sign-in is required to join. Guest mode cannot start a call.',
      );
    }
    if (response.statusCode == 503) {
      throw const StreamTokenException('Video calling is not configured on this preview yet.');
    }
    if (response.statusCode != 200) {
      throw const StreamTokenException('The call could not start. Try again in a moment.');
    }
    return parseStreamTokenResponse(response.body, requestedCallId: callId);
  }
}

StreamCallCredentials parseStreamTokenResponse(String body, {required String requestedCallId}) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const StreamTokenException('The call could not start. Try again in a moment.');
  }
  if (decoded.containsKey('apiSecret') || decoded.containsKey('secret')) {
    throw const StreamTokenException('The call could not start. Try again in a moment.');
  }
  final apiKey = decoded['apiKey'];
  final token = decoded['token'];
  final userId = decoded['userId'];
  final expiresAt = decoded['expiresAt'];
  if (apiKey is! String || apiKey.trim().isEmpty || apiKey.contains(' ')) {
    throw const StreamTokenException('Video calling is not configured on this preview yet.');
  }
  if (token is! String || !_looksLikeUserToken(token)) {
    throw const StreamTokenException('The call could not start. Try again in a moment.');
  }
  if (userId is! String || userId.trim().isEmpty) {
    throw const StreamTokenException('The call could not start. Try again in a moment.');
  }
  return StreamCallCredentials(
    apiKey: apiKey.trim(),
    token: token,
    userId: userId.trim(),
    callId: requestedCallId,
    expiresAt: expiresAt is int ? expiresAt : 0,
  );
}

bool _looksLikeUserToken(String token) {
  final parts = token.split('.');
  return parts.length == 3 && parts.every((part) => part.isNotEmpty) && !token.contains(' ');
}

/// Firebase ID token for the signed-in member. Null when Firebase auth is absent.
Future<String?> readFirebaseIdToken() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  } catch (_) {
    return null;
  }
}
