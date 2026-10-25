/// Checks the optional "name or email" field on the feedback sheet.
///
/// Empty text is allowed. A name with no `@` is allowed. A value that
/// contains `@` must be one full address so organizers can reply.
abstract final class OptionalFeedbackContact {
  /// Shown under the field when a value contains `@` but is not an address.
  static const emailError =
      "That doesn't look like an email. Use a name, or a full address like name@example.com.";

  /// Anchored form of the address shape used when logs redact emails, so a
  /// fragment such as `not@email` does not pass.
  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
  );

  /// Inline error for [raw], or null when the contact may be submitted.
  static String? errorText(String raw) {
    final contact = raw.trim();
    if (contact.isEmpty || !contact.contains('@')) return null;
    if (_emailPattern.hasMatch(contact)) return null;
    return emailError;
  }
}
