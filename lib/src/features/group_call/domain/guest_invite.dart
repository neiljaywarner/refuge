import 'group_call_room.dart';

final RegExp _inviteTokenPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// Link details returned once when a member creates a guest invite.
class const GuestInvite({
  required this.token,
  required this.callId,
  required this.expiresAt,
  required this.guestLimit,
}) {
  final String token;
  final String callId;
  final int expiresAt;
  final int guestLimit;
}

bool inviteTokenLooksValid(String token) => _inviteTokenPattern.hasMatch(token);

String? _tokenFrom(String? raw) {
  if (raw == null || !inviteTokenLooksValid(raw)) return null;
  return raw;
}

/// Invite token from `?invite=` on the page, including a hash-route fallback.
///
/// A call name without this token is not an invite. A short or punctuated
/// value is ignored so a random query does not open the guest door.
String? guestInviteFromLocation(Uri uri) {
  final direct = _tokenFrom(uri.queryParameters['invite']);
  if (direct != null) return direct;
  return _tokenFrom(_fragmentQuery(uri)['invite']);
}

/// Call name only when the page actually asked for one.
///
/// Missing or invalid `call` stays null. It does not fall back to `monthly`,
/// because a guest invite must not be joined to a different room by default.
String? explicitGroupCallIdFromLocation(Uri uri) {
  if (uri.queryParameters.containsKey('call')) {
    return GroupCallRoom.tryParse(uri.queryParameters['call'] ?? '')?.id;
  }
  final fragment = _fragmentQuery(uri);
  if (!fragment.containsKey('call')) return null;
  return GroupCallRoom.tryParse(fragment['call'] ?? '')?.id;
}

Map<String, String> _fragmentQuery(Uri uri) {
  final fragment = uri.fragment;
  final queryIndex = fragment.indexOf('?');
  if (queryIndex < 0) return const {};
  return Uri.splitQueryString(fragment.substring(queryIndex + 1));
}

/// Page link a member can copy. The token is the secret. The call name is not.
Uri guestInvitePageUri({required Uri page, required String callId, required String inviteToken}) {
  return Uri(
    scheme: page.scheme,
    host: page.host,
    port: page.hasPort ? page.port : null,
    path: page.path,
    queryParameters: {'call': callId, 'invite': inviteToken},
  );
}
