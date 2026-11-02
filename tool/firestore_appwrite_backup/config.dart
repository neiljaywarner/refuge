import 'errors.dart';

/// Public project ids plus secrets read from the environment.
///
/// The endpoint, Appwrite project id, database id, and Firestore project id
/// are already in the client. They are not secrets. `APPWRITE_API_KEY` and
/// `FIRESTORE_ACCESS_TOKEN` are secrets and have no default.
class const BackupConfig({
  required final String endpoint,
  required final String projectId,
  required final String databaseId,
  required final String firestoreProjectId,
  final String? apiKey,
  final String? firestoreAccessToken,
}) {
  static const defaultEndpoint = 'https://nyc.cloud.appwrite.io/v1';
  static const defaultProjectId = '6adae5c40013c409e109';
  static const defaultDatabaseId = 'belong_community_db';
  static const defaultFirestoreProjectId = 'belongonthespectrum';

  static BackupConfig fromEnvironment(Map<String, String> env) {
    final endpoint = (env['APPWRITE_ENDPOINT'] ?? defaultEndpoint).trim();
    final projectId = (env['APPWRITE_PROJECT_ID'] ?? defaultProjectId).trim();
    final databaseId = (env['APPWRITE_DATABASE_ID'] ?? defaultDatabaseId).trim();
    final firestoreProjectId = (env['FIRESTORE_PROJECT_ID'] ?? defaultFirestoreProjectId).trim();
    final apiKey = env['APPWRITE_API_KEY']?.trim();
    final token = env['FIRESTORE_ACCESS_TOKEN']?.trim();
    return BackupConfig(
      endpoint: endpoint,
      projectId: projectId,
      databaseId: databaseId,
      firestoreProjectId: firestoreProjectId,
      apiKey: apiKey == null || apiKey.isEmpty ? null : apiKey,
      firestoreAccessToken: token == null || token.isEmpty ? null : token,
    );
  }

  String get normalizedEndpoint {
    final trimmed = endpoint.trim();
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;

  bool get hasFirestoreToken => firestoreAccessToken != null && firestoreAccessToken!.isNotEmpty;

  void requireHttps() {
    final uri = Uri.tryParse(normalizedEndpoint);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw BackupCliException('APPWRITE_ENDPOINT must be an https URL.', 78);
    }
  }
}

String redactSecrets(String text, BackupConfig config) {
  var output = text;
  final key = config.apiKey;
  final token = config.firestoreAccessToken;
  if (key != null && key.isNotEmpty) {
    output = output.replaceAll(key, '[redacted]');
  }
  if (token != null && token.isNotEmpty) {
    output = output.replaceAll(token, '[redacted]');
  }
  return output;
}
