/// Display name on a preview call.
///
/// An empty name, or one that contains an email address, becomes
/// "Fellow Member" so the room does not show a sign-in address.
String calmGroupCallName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.contains('@')) return 'Fellow Member';
  return trimmed;
}

/// Member-facing text for a failed call.
///
/// Stream errors can echo a JWT (`eyJ…`), the word "token" or "secret", or a
/// long SDK dump. Those become one calm sentence so a credential is not
/// painted on screen. A short ordinary message is shown as written.
String calmGroupCallFailureText(String raw) {
  final lower = raw.toLowerCase();
  if (raw.trim().isEmpty ||
      raw.length > 160 ||
      lower.contains('secret') ||
      lower.contains('token') ||
      raw.contains('eyJ')) {
    return 'The call could not connect.';
  }
  return raw.trim();
}
