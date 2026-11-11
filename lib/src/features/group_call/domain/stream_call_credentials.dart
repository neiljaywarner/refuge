/// Credentials returned by the preview token function.
///
/// [apiKey] is Stream's public key. [token] is a user token. The API secret
/// is never part of this value.
class const StreamCallCredentials({
  required this.apiKey,
  required this.token,
  required this.userId,
  required this.callId,
  required this.expiresAt,
  this.role = 'member',
  this.displayName = '',
  this.seatKey = '',
}) {
  final String apiKey;
  final String token;
  final String userId;
  final String callId;
  final int expiresAt;

  /// `member` for a Firebase sign-in, or `guest` for an invite join.
  final String role;
  final String displayName;

  /// Guest seat credential. Empty for a member. Not a Stream API secret.
  final String seatKey;

  bool get isGuest => role == 'guest';
}
