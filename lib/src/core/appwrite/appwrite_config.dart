/// Opt-in Appwrite project settings.
///
/// Empty values keep the app on the current live path: Serverpod for posts
/// and reactions, with Firebase Cloud Firestore as the second copy. Appwrite
/// is not contacted unless both an endpoint and a project id are supplied at
/// build time.
class AppwriteConfig {
  const AppwriteConfig({
    required this.endpoint,
    required this.projectId,
    this.databaseId = 'belong_community_db',
  });

  /// Reads `--dart-define=APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, and
  /// `APPWRITE_DATABASE_ID`. Defaults are empty, so a normal `flutter run`
  /// does not switch backends.
  static const fromEnvironment = AppwriteConfig(
    endpoint: String.fromEnvironment('APPWRITE_ENDPOINT'),
    projectId: String.fromEnvironment('APPWRITE_PROJECT_ID'),
    databaseId: String.fromEnvironment(
      'APPWRITE_DATABASE_ID',
      defaultValue: 'belong_community_db',
    ),
  );

  final String endpoint;
  final String projectId;
  final String databaseId;

  /// True only when a real https endpoint and project id were provided.
  bool get isConfigured {
    final trimmedEndpoint = endpoint.trim();
    final trimmedProject = projectId.trim();
    if (trimmedEndpoint.isEmpty || trimmedProject.isEmpty) return false;
    final uri = Uri.tryParse(trimmedEndpoint);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    if (trimmedEndpoint.contains('<') || trimmedProject.contains('your-')) {
      return false;
    }
    return true;
  }
}
