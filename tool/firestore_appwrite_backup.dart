import 'dart:io';

import 'firestore_appwrite_backup/cli.dart';

/// Copies Firestore documents into Appwrite backup tables.
///
/// ```bash
/// dart run tool/firestore_appwrite_backup.dart help
/// ```
///
/// Secrets stay in `APPWRITE_API_KEY` and `FIRESTORE_ACCESS_TOKEN`.
/// This file does not contain them.
Future<void> main(List<String> args) async {
  exitCode = await runFirestoreAppwriteBackup(args);
}
