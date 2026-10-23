import 'package:appwrite/appwrite.dart';

import 'appwrite_config.dart';

/// Appwrite services created only after [AppwriteConfig.isConfigured] is true.
///
/// The live feed still uses [ServerpodPostRepository], which also writes a
/// copy to Cloud Firestore. This object is the first seam for a later
/// migration and does not replace those writes.
class AppwriteServices {
  AppwriteServices(this.client)
      : account = Account(client),
        databases = Databases(client),
        realtime = Realtime(client);

  final Client client;
  final Account account;
  final Databases databases;
  final Realtime realtime;
}

/// Returns null when Appwrite is not configured, so callers keep Serverpod
/// and Firestore.
AppwriteServices? createAppwriteServices(AppwriteConfig config) {
  if (!config.isConfigured) return null;
  final client = Client()
      .setEndpoint(config.endpoint.trim())
      .setProject(config.projectId.trim());
  return AppwriteServices(client);
}
