import 'package:appwrite/appwrite.dart';

import 'appwrite_config.dart';

/// Appwrite services created only after [AppwriteConfig.isConfigured] is true.
///
/// The feed writes reflections here and keeps a second copy in Cloud Firestore.
/// [Account] is available for a later auth migration. Sign-in still uses
/// Firebase Auth.
class AppwriteServices {
  AppwriteServices(this.client)
    : account = Account(client),
      databases = Databases(client),
      tables = TablesDB(client),
      realtime = Realtime(client);

  final Client client;
  final Account account;
  final Databases databases;
  final TablesDB tables;
  final Realtime realtime;
}

/// Returns null when Appwrite is not configured. Callers then keep Firestore
/// and the local reflection cache, and still do not call Serverpod.
AppwriteServices? createAppwriteServices(AppwriteConfig config) {
  if (!config.isConfigured) return null;
  final client = Client().setEndpoint(config.endpoint.trim()).setProject(config.projectId.trim());
  return AppwriteServices(client);
}
