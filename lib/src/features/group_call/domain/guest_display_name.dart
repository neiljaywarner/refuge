final RegExp _guestNameControls = RegExp(r'[\u0000-\u001F\u007F]');
final RegExp _guestNameBidi = RegExp(r'[\u202A-\u202E\u2066-\u2069]');
final RegExp _guestNameScheme = RegExp(r'[a-zA-Z][a-zA-Z0-9+.-]*://');

/// Name a guest may show on the call.
///
/// Trims ordinary spaces. Rejects an empty name, a name longer than 40
/// characters, control characters, an email address, and an obvious web link.
String? sanitizeGuestDisplayName(String raw) {
  if (_guestNameControls.hasMatch(raw) || _guestNameBidi.hasMatch(raw)) return null;
  final trimmed = raw.trim().replaceAll(RegExp(' +'), ' ');
  if (trimmed.isEmpty || trimmed.length > 40) return null;
  if (trimmed.contains('@')) return null;
  if (trimmed.toLowerCase().contains('www.') || _guestNameScheme.hasMatch(trimmed)) return null;
  return trimmed;
}
