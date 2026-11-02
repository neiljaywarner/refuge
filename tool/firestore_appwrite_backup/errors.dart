/// Exit codes for the Firestore → Appwrite backup CLI.
///
/// `64` usage, `65` data, `70` remote call failed, `78` configuration.
class BackupCliException implements Exception {
  BackupCliException(this.message, this.exitCode);

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}
