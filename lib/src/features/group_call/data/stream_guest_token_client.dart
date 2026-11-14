import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/group_call_analytics.dart';
import '../domain/guest_display_name.dart';
import '../domain/stream_call_credentials.dart';
import 'stream_token_client.dart';

// The constructor parameter stays httpClient, matching StreamTokenClient.
// ignore_for_file: prefer_initializing_formals

/// Joins a preview call with an invite token. There is no Firebase sign-in.
class StreamGuestTokenClient implements GroupCallTokenSource {
  StreamGuestTokenClient({
    required this.endpoint,
    required this.inviteToken,
    required http.Client httpClient,
    this.callId,
  }) : _httpClient = httpClient;

  final Uri endpoint;
  final String inviteToken;
  final String? callId;
  final http.Client _httpClient;
  String? _guestUserId;
  String? _seatKey;
  String _displayName = '';
  bool _closed = false;

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _httpClient.close();
  }

  /// Checks the name locally, then asks the function for a guest token.
  Future<StreamCallCredentials> join({required String displayName}) =>
      _guard('join_guest', () async {
        final clean = sanitizeGuestDisplayName(displayName);
        if (clean == null) {
          throw const StreamTokenException(
            'Use a short name. Leave out email addresses and web links.',
          );
        }
        final credentials = await _request(displayName: clean, guestUserId: null);
        if (credentials.seatKey.isEmpty) {
          throw const StreamTokenException(streamTokenUnavailableMessage);
        }
        _guestUserId = credentials.userId;
        _seatKey = credentials.seatKey;
        _displayName = credentials.displayName;
        return credentials;
      });

  /// Refreshes the same guest seat. Does not take a second seat.
  @override
  Future<StreamCallCredentials> mint({required String callId}) => _guard('refresh_guest', () async {
    if (this.callId != null && this.callId != callId) {
      throw const StreamTokenException('This invite link is for a different call.');
    }
    if (_displayName.isEmpty) {
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
    return _request(displayName: _displayName, guestUserId: _guestUserId, seatKey: _seatKey);
  });

  /// Reports a handled guest failure, then rethrows a calm sentence.
  ///
  /// A malformed body throws [FormatException]. That message can quote the
  /// response, so it is recorded as `unavailable` and is not copied into the event.
  Future<T> _guard<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } on StreamTokenException catch (error, stack) {
      await GroupCallTelemetry.current?.failed(
        role: 'guest',
        action: action,
        failureReason: callFailureReasonForMessage(error.message),
        stack: stack,
      );
      rethrow;
    } on FormatException catch (_, stack) {
      await GroupCallTelemetry.current?.failed(
        role: 'guest',
        action: action,
        failureReason: 'unavailable',
        stack: stack,
      );
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
  }

  /// Gives the seat back. A failure still lets the person leave the screen.
  @override
  Future<void> release() async {
    final guestUserId = _guestUserId;
    final seatKey = _seatKey;
    if (_closed || guestUserId == null || seatKey == null) return;
    try {
      await _httpClient.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'releaseGuest',
          'inviteToken': inviteToken,
          'guestUserId': guestUserId,
          'seatKey': seatKey,
        }),
      );
    } catch (_) {
      // The seat expires with the short token if this request does not land.
    }
  }

  Future<StreamCallCredentials> _request({
    required String displayName,
    required String? guestUserId,
    String? seatKey,
  }) async {
    if (_closed) throw const StreamTokenException(streamTokenUnavailableMessage);
    final payload = <String, Object?>{
      'action': 'joinGuest',
      'inviteToken': inviteToken,
      'displayName': displayName,
    };
    final room = callId;
    if (room != null) payload['callId'] = room;
    if (guestUserId != null) payload['guestUserId'] = guestUserId;
    if (seatKey != null) payload['seatKey'] = seatKey;
    final http.Response response;
    try {
      response = await _httpClient.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
    if (response.statusCode != 200) {
      throw StreamTokenException(_guestFailure(response.statusCode, response.body));
    }
    final credentials = parseStreamTokenResponse(response.body, requestedCallId: room ?? '');
    if (!credentials.isGuest) {
      throw const StreamTokenException(streamTokenUnavailableMessage);
    }
    return credentials;
  }
}

String _guestFailure(int statusCode, String body) {
  if (_bodyLooksSecret(body)) return streamTokenUnavailableMessage;
  final code = _code(body);
  return switch (code) {
    'name' => 'Use a short name. Leave out email addresses and web links.',
    'not-found' => 'This invite link is not valid.',
    'expired' || 'revoked' => 'This invite link has expired or was revoked.',
    'cap' => 'This call already has 10 guests. Try again after someone leaves.',
    'mismatch' => 'This invite link is for a different call.',
    'seat' => 'This invite link is not valid for that seat. Open the link again.',
    'rate' => 'Too many join attempts. Wait a few minutes and try the link again.',
    'unconfigured' => streamVideoUnconfiguredMessage,
    'room' => 'The call could not be prepared. Try again in a moment.',
    _ => switch (statusCode) {
      400 => 'Use a short name. Leave out email addresses and web links.',
      404 => 'This invite link is not valid.',
      410 => 'This invite link has expired or was revoked.',
      409 => 'This call already has 10 guests. Try again after someone leaves.',
      429 => 'Too many join attempts. Wait a few minutes and try the link again.',
      403 => 'This invite link is for a different call.',
      503 => streamVideoUnconfiguredMessage,
      _ => streamTokenUnavailableMessage,
    },
  };
}

bool _bodyLooksSecret(String body) {
  try {
    final decoded = jsonDecode(body);
    return decoded is Map && (decoded.containsKey('apiSecret') || decoded.containsKey('secret'));
  } catch (_) {
    return false;
  }
}

String? _code(String body) {
  try {
    final decoded = jsonDecode(body);
    final code = decoded is Map ? decoded['code'] : null;
    return code is String ? code : null;
  } catch (_) {
    return null;
  }
}
