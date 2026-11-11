/// Short room name for a preview group call (#872).
///
/// Names are lowercase letters, numbers, and single dashes, 3 to 40 characters.
class const GroupCallRoom(final String id) {
  static const String defaultId = 'monthly';

  static final RegExp _pattern = RegExp(r'^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$');

  static GroupCallRoom? tryParse(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    if (normalized.contains('--') || !_pattern.hasMatch(normalized)) return null;
    return GroupCallRoom(normalized);
  }
}

/// A signed-in member may end the call or remove someone when they created
/// the room, or when Stream gave them host or admin.
///
/// A guest cannot, even if they were first in the room or the request claims
/// a host role. [signedInMember] is Belong sign-in, not Stream's owner flag.
bool canModerateGroupCall({
  required bool signedInMember,
  required bool createdByMe,
  required Iterable<String> roles,
}) {
  if (!signedInMember) return false;
  if (createdByMe) return true;
  for (final role in roles) {
    final normalized = role.toLowerCase();
    if (normalized == 'admin' || normalized == 'host') return true;
  }
  return false;
}

/// Call name from `?call=` on the page, including a hash-route fallback.
String groupCallIdFromLocation(Uri uri) {
  final direct = GroupCallRoom.tryParse(uri.queryParameters['call'] ?? '');
  if (direct != null) return direct.id;
  final fragment = uri.fragment;
  final queryIndex = fragment.indexOf('?');
  if (queryIndex >= 0) {
    final fromFragment = GroupCallRoom.tryParse(
      Uri.splitQueryString(fragment.substring(queryIndex + 1))['call'] ?? '',
    );
    if (fromFragment != null) return fromFragment.id;
  }
  return GroupCallRoom.defaultId;
}
