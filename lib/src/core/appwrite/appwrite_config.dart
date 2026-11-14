/// Public Appwrite client settings for the belongonthespectrum project.
///
/// These values identify the project. They are not secrets. Firebase Auth
/// remains the session. ADR-0011 disables client writes to these tables until
/// a signed-in Appwrite session, or a server holding an API key, exists.
/// Cloud Firestore is the live reflection store.
///
/// Pass an empty `--dart-define=APPWRITE_ENDPOINT=` to skip Appwrite.
/// Firestore remains the live community store.
class AppwriteConfig {
  const AppwriteConfig({
    required this.endpoint,
    required this.projectId,
    this.databaseId = belongDatabaseId,
  });

  static const belongEndpoint = 'https://nyc.cloud.appwrite.io/v1';
  static const belongProjectId = '6adae5c40013c409e109';
  static const belongDatabaseId = 'belong_community_db';
  static const reflectionTableId = 'reflection_posts';
  static const quietDigestTableId = 'quiet_digests';
  static const clientSessionAuditsTableId = 'client_session_audits';
  static const clientSessionWeeklySummariesTableId = 'client_session_weekly_summaries';

  /// Reads `--dart-define=APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, and
  /// `APPWRITE_DATABASE_ID`. Defaults point at the live belong project.
  static const fromEnvironment = AppwriteConfig(
    endpoint: String.fromEnvironment('APPWRITE_ENDPOINT', defaultValue: belongEndpoint),
    projectId: String.fromEnvironment('APPWRITE_PROJECT_ID', defaultValue: belongProjectId),
    databaseId: String.fromEnvironment('APPWRITE_DATABASE_ID', defaultValue: belongDatabaseId),
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
