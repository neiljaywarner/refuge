/// Shared-device scope for private local caches.
///
/// Bookmarks and the pending-post outbox must not use one device-global key.
/// [environment] follows the reflection partition (`dev` or `prod`).
/// A missing account is `signed_out`, which is a different bucket from every uid.
String localAccountScope({required String environment, String? accountId}) {
  final env = environment.trim().isEmpty ? 'prod' : environment.trim();
  final who = accountId?.trim();
  final owner = (who == null || who.isEmpty) ? 'signed_out' : who;
  return '${env}_$owner';
}

/// `dev` when the reflection store is the dev collection, otherwise `prod`.
String reflectionEnvironment({required bool isDevMode}) => isDevMode ? 'dev' : 'prod';
