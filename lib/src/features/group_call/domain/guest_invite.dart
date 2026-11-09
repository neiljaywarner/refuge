import 'package:flutter/foundation.dart';

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

/// Dev preview site. A phone build has no browser address, so the share link
/// uses this https origin instead of `file://`.
final Uri previewGuestInviteOrigin = Uri.parse('https://dev-belongonthespectrum.web.app/');

/// Page link a member can copy. The token is the secret. The call name is not.
///
/// [page] is used only when it is https, or loopback http for the emulator.
/// A `file://` base, which is what Android reports, is replaced by [shareOrigin].
Uri guestInvitePageUri({
  required Uri page,
  required String callId,
  required String inviteToken,
  Uri? shareOrigin,
}) {
  final webPage = _webPage(page);
  final base = webPage ?? shareOrigin ?? previewGuestInviteOrigin;
  final path = webPage != null && page.path.isNotEmpty
      ? page.path
      : (base.path.isEmpty ? '/' : base.path);
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: path,
    queryParameters: {'call': callId, 'invite': inviteToken},
  );
}

/// Invite address from a cold start or a later VIEW intent.
///
/// [platformRoute] is the Android/iOS route (`defaultRouteName` or
/// `didPushRouteInformation`). [page] is [Uri.base], which is `file://` on a
/// phone. A valid invite on the route wins. A call name alone does not.
Uri? guestInviteUriFromLaunch({required String platformRoute, required Uri page}) {
  final fromRoute = _routeUri(platformRoute);
  if (fromRoute != null && guestInviteFromLocation(fromRoute) != null) return fromRoute;
  if (guestInviteFromLocation(page) != null) return page;
  return null;
}

Uri? _webPage(Uri page) {
  if (page.userInfo.isNotEmpty || page.host.isEmpty) return null;
  if (page.scheme == 'https') return page;
  final loopback = page.host == 'localhost' || page.host == '127.0.0.1';
  if (page.scheme == 'http' && loopback) return page;
  return null;
}

Uri? _routeUri(String route) {
  final trimmed = route.trim();
  if (trimmed.isEmpty || trimmed == '/') return null;
  return Uri.tryParse(trimmed);
}

/// Holds the invite link from a cold start or a later Android VIEW intent.
///
/// AuthGate listens so a signed-out preview build can show the name page
/// without waiting for [Uri.base], which stays `file://` on a phone.
class GuestInviteSignals extends ChangeNotifier {
  Uri? _location;

  Uri? get location => _location;

  void present(Uri? uri) {
    if (uri == null || guestInviteFromLocation(uri) == null) return;
    if (_location?.toString() == uri.toString()) return;
    _location = uri;
    notifyListeners();
  }
}
