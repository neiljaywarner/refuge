/// Whether an opted-in device should get an OS notification for a new direct message.
///
/// Push is off until the member turns it on in Settings. A muted schedule
/// also sends nothing. Placeholder tokens from tests are never delivered.
bool shouldSendDirectMessagePush({
  required bool enabled,
  required String schedule,
  required String? fcmToken,
}) {
  if (!enabled || schedule == 'muted') return false;
  final token = fcmToken?.trim() ?? '';
  if (token.isEmpty || token.startsWith('fcm_token_calm')) return false;
  return true;
}

/// Immediate Gentle Cards is the quiet extra. Every other on schedule uses
/// the normal Direct messages channel, with sound.
bool directMessageIsQuiet(String schedule) => schedule == 'immediateGentle';

/// Shade text. The snippet is short and never includes an email address.
String directMessagePushBody({required String senderName, required String content}) {
  final name = senderName.trim().isEmpty ? 'Fellow Member' : senderName.trim();
  final snippet = content.trim();
  if (snippet.isEmpty) return '$name sent you a direct message';
  final short = snippet.length <= 80 ? snippet : snippet.substring(0, 80);
  return '$name sent you a direct message: "$short"';
}
