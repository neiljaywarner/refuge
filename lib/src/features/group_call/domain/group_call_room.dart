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

/// The person who created the room, or a Stream host/admin, may end it
/// or remove someone. Everyone else can only leave.
bool canModerateGroupCall({required bool createdByMe, required Iterable<String> roles}) {
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
