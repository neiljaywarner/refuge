import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/group_call_analytics.dart';
import '../domain/group_call_room.dart';
import '../domain/guest_display_name.dart';
import '../domain/guest_invite.dart';
import '../domain/stream_call_credentials.dart';

// Public constructor names stay httpClient and readIdToken.
// ignore_for_file: prefer_initializing_formals

class StreamTokenException implements Exception {
  const StreamTokenException(this.message);
  final String message;
}

const String streamSignInRequiredMessage =
    'A Firebase sign-in is required to join by call name. '
    'The call name alone does not let anyone in.';

const String streamTokenUnavailableMessage = 'The call could not start. Try again in a moment.';

const String streamVideoUnconfiguredMessage =
    'Video calling is not configured on this preview yet.';

/// Something that can refresh a call token and release a guest seat.
abstract class GroupCallTokenSource {
  Future<StreamCallCredentials> mint({required String callId});
  Future<void> release();
  void close();
}

/// Asks the preview function for a user token. The secret never leaves the function.
class StreamTokenClient implements GroupCallTokenSource {
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

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _httpClient.close();
  }

  /// A signed-in member has no guest seat to release.
  @override
  Future<void> release() async {}

  /// Asks [endpoint] for a user token.
  ///
  /// The `Authorization` bearer is the Firebase ID token, not a Stream secret.
  /// The function checks that token and mints the user token. A 401 means
  /// sign-in failed. A 503 means the function has no API key or secret yet.
  /// Any other status becomes a generic sentence: the response body is not
  /// shown, because a misconfigured function might echo a credential.
  @override
  Future<StreamCallCredentials> mint({required String callId}) => _guard('mint', () async {
    final response = await _authorizedPost({'callId': callId});
    if (response.statusCode != 200) throw _memberFailure(response.statusCode);
    return parseStreamTokenResponse(response.body, requestedCallId: callId);
  });

  /// Creates a one-day guest link for [callId]. The token is returned once.
  Future<GuestInvite> createGuestInvite({required String callId}) =>
      _guard('create_invite', () async {
        final response = await _authorizedPost({'action': 'createInvite', 'callId': callId});
        if (response.statusCode != 200) throw _memberFailure(response.statusCode);
        return parseGuestInviteResponse(response.body);
      });

  /// Revokes every link this member created for [callId], including ones
  /// this screen no longer has. The raw tokens are not returned.
  Future<void> revokeMyGuestInvites({required String callId}) =>
      _guard('revoke_my_invites', () async {
        final response = await _authorizedPost({'action': 'revokeMyInvites', 'callId': callId});
        if (response.statusCode != 200) throw _memberFailure(response.statusCode);
        if (_bodyContainsSecret(response.body)) {
          throw const StreamTokenException(streamTokenUnavailableMessage);
        }
      });

  /// Revokes a link this member created. The token is not shown if this fails.
  Future<void> revokeGuestInvite({required String inviteToken}) =>
      _guard('revoke_invite', () async {
        final response = await _authorizedPost({
          'action': 'revokeInvite',
          'inviteToken': inviteToken,
        });
        if (response.statusCode != 200) throw _memberFailure(response.statusCode);
        if (_bodyContainsSecret(response.body)) {
          throw const StreamTokenException(streamTokenUnavailableMessage);
        }
      });

  /// Reports a handled mint or invite failure, then rethrows a calm sentence.
  ///
  /// A malformed body throws [FormatException], and that message can quote the
  /// response. It is recorded as `unavailable` and is not copied into the event.
  Future<T> _guard<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } on StreamTokenException catch (error, stack) {
      await GroupCallTelemetry.current?.failed(
        role: 'member',
        action: action,
        failureReason: callFailureReasonForMessage(error.message),
        stack: stack,
      );
      rethrow;
    } on FormatException catch (_, stack) {
      await GroupCallTelemetry.current?.failed(
        role: 'member',
        action: action,
        failureReason: 'unavailable',
        stack: stack,
      );
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
  }

  Future<http.Response> _authorizedPost(Map<String, Object?> payload) async {
    if (_closed) {
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
    final String? idToken;
    try {
      idToken = await _readIdToken();
    } catch (_) {
      // The reader failure may mention a credential. The sentence does not.
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
    if (idToken == null || idToken.isEmpty) {
      throw const StreamTokenException(streamSignInRequiredMessage);
    }
    try {
      return await _httpClient.post(
        endpoint,
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
  }
}

StreamTokenException _memberFailure(int statusCode) {
  if (statusCode == 401) return const StreamTokenException(streamSignInRequiredMessage);
  if (statusCode == 403) {
    return const StreamTokenException('This account cannot join a call.');
  }
  if (statusCode == 503) return const StreamTokenException(streamVideoUnconfiguredMessage);
  return const StreamTokenException(streamTokenUnavailableMessage);
}

/// Reads the mint response. `apiKey` here is Stream's public key.
///
/// A body that includes `apiSecret` or `secret` is refused, even when the
/// other fields look valid, so this client never stores a secret that a
/// broken function echoed back.
StreamCallCredentials parseStreamTokenResponse(String body, {required String requestedCallId}) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const StreamTokenException('The call could not start. Try again in a moment.');
  }
  if (_mapContainsSecret(decoded)) {
    throw const StreamTokenException(streamTokenUnavailableMessage);
  }
  final apiKey = decoded['apiKey'];
  final token = decoded['token'];
  final userId = decoded['userId'];
  final expiresAt = decoded['expiresAt'];
  if (apiKey is! String || apiKey.trim().isEmpty || apiKey.contains(' ')) {
    throw const StreamTokenException(streamVideoUnconfiguredMessage);
  }
  if (token is! String || !_looksLikeUserToken(token)) {
    throw const StreamTokenException(streamTokenUnavailableMessage);
  }
  if (userId is! String || userId.trim().isEmpty) {
    throw const StreamTokenException(streamTokenUnavailableMessage);
  }
  final guest = decoded['actor'] == 'guest';
  if (guest) {
    if (decoded['canModerate'] == true) {
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
    if (decoded['callRole'] != 'call-member') {
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
    final name = decoded['displayName'];
    final clean = name is String ? sanitizeGuestDisplayName(name) : null;
    if (clean == null) throw const StreamTokenException(streamTokenUnavailableMessage);
    final responseCallId = decoded['callId'];
    if (responseCallId is! String || GroupCallRoom.tryParse(responseCallId) == null) {
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
    if (requestedCallId.isNotEmpty && responseCallId != requestedCallId) {
      throw const StreamTokenException('This invite link is for a different call.');
    }
    final rawSeat = decoded['seatKey'];
    var seatKey = '';
    if (rawSeat != null) {
      if (rawSeat is! String || !inviteTokenLooksValid(rawSeat)) {
        throw const StreamTokenException(streamTokenUnavailableMessage);
      }
      seatKey = rawSeat;
    }
    return StreamCallCredentials(
      apiKey: apiKey.trim(),
      token: token,
      userId: userId.trim(),
      callId: responseCallId,
      expiresAt: expiresAt is int ? expiresAt : 0,
      role: 'guest',
      displayName: clean,
      seatKey: seatKey,
    );
  }
  return StreamCallCredentials(
    apiKey: apiKey.trim(),
    token: token,
    userId: userId.trim(),
    callId: requestedCallId,
    expiresAt: expiresAt is int ? expiresAt : 0,
  );
}

/// Reads a create-invite response. A body that echoes a secret is refused.
GuestInvite parseGuestInviteResponse(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map || _mapContainsSecret(decoded)) {
    throw const StreamTokenException(streamTokenUnavailableMessage);
  }
  final token = decoded['inviteToken'];
  final callId = decoded['callId'];
  final expiresAt = decoded['expiresAt'];
  final guestLimit = decoded['guestLimit'];
  if (token is! String || !inviteTokenLooksValid(token)) {
    throw const StreamTokenException(streamTokenUnavailableMessage);
  }
  if (callId is! String || GroupCallRoom.tryParse(callId) == null) {
    throw const StreamTokenException(streamTokenUnavailableMessage);
  }
  if (expiresAt is! int || guestLimit is! int || guestLimit < 1) {
    throw const StreamTokenException(streamTokenUnavailableMessage);
  }
  return GuestInvite(token: token, callId: callId, expiresAt: expiresAt, guestLimit: guestLimit);
}

bool _bodyContainsSecret(String body) {
  try {
    final decoded = jsonDecode(body);
    return decoded is Map && _mapContainsSecret(decoded);
  } catch (_) {
    return false;
  }
}

bool _mapContainsSecret(Map<dynamic, dynamic> decoded) =>
    decoded.containsKey('apiSecret') || decoded.containsKey('secret');

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
