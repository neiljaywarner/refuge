/// Whether a member should get a calm email for a new direct message.
///
/// This is the Dart copy of `functions/src/decide.js`. Change both together.
/// Alerts stay off until the member turns them on. A muted schedule sends
/// nothing. The address is the member's sign-in email, read by the Cloud
/// Function. It is never placed in the subject.
bool shouldSendDirectMessageEmail({
  required bool enabled,
  required String schedule,
  required String? email,
}) {
  if (!enabled || schedule == 'muted') return false;
  return isDeliverableDirectMessageAddress(email);
}

/// A stored `direct_messages` document is the only send the email function sees.
///
/// Sample threads use `localOnly`. A send that never reached Firestore uses
/// `deviceOnly`. Neither one creates the document, so neither one can email.
bool directMessageOutcomeCreatesStoredDocument(String outcomeName) => outcomeName == 'delivered';

/// True when [email] can be a delivery address. Spaces and a missing `@` cannot.
bool isDeliverableDirectMessageAddress(String? email) {
  final address = email?.trim() ?? '';
  if (address.isEmpty || address.contains(' ') || address.contains('\n')) return false;
  final at = address.indexOf('@');
  if (at <= 0 || at != address.lastIndexOf('@') || at == address.length - 1) return false;
  return true;
}

/// Display name for the mail. An address, a blank, or the message body becomes
/// "Fellow Member" so the subject cannot carry either.
String calmDirectMessageSenderName({required String senderName, required String content}) {
  final name = senderName.replaceAll(RegExp(r'\s+'), ' ').trim();
  final body = content.trim();
  if (name.isEmpty || name.contains('@') || name.contains('\n')) return 'Fellow Member';
  if (body.length >= 8 && (name == body || name.contains(body))) return 'Fellow Member';
  if (name.length > 80) return name.substring(0, 80).trim();
  return name;
}

/// Subject line. Names the sender and says a message is waiting.
///
/// The full message and any email address stay out of this string.
String directMessageEmailSubject({required String senderName, required String content}) {
  final name = calmDirectMessageSenderName(senderName: senderName, content: content);
  final subject = '$name — a message is waiting';
  if (subject.contains('@')) return 'Fellow Member — a message is waiting';
  final body = content.trim();
  if (body.length >= 8 && subject.contains(body)) {
    return 'Fellow Member — a message is waiting';
  }
  return subject;
}

/// Plain-text body. It names the sender and does not quote the message.
String directMessageEmailText({required String senderName, required String content}) {
  final name = calmDirectMessageSenderName(senderName: senderName, content: content);
  return '$name sent you a message in Belong. Open the app when you are ready.';
}
