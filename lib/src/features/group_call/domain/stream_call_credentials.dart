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
}) {
  final String apiKey;
  final String token;
  final String userId;
  final String callId;
  final int expiresAt;
}
