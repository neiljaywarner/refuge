import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/appwrite/appwrite_client_factory.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/config/app_flavor.dart';
import '../../auth/data/auth_backend_target.dart';
import '../../feedback/data/feature_voting_repository.dart';
import '../domain/account_deletion_record.dart';
import 'account_deletion_sinks.dart';

/// Set when FirebaseUI must undo a sign-in for a soft-deleted account.
final softDeleteSignInNoticeProvider = StateProvider<String?>((ref) => null);

/// Active self-service deletion backend for the signed-in member.
///
/// Firebase and Appwrite targets write Cloud Firestore. An Appwrite project
/// configured at build time also stores prefs on the current account.
/// Memory is used for tests and the offline auth adapters.
final accountDeletionRepositoryProvider = Provider<AccountDeletionRepository>((ref) {
  final flavor = ref.watch(appFlavorProvider).slug;
  final target = ref.watch(authBackendTargetProvider);
  final useFirestore = target == BackendTarget.firebase || target == BackendTarget.appwrite;
  final sinks = <AccountDeletionSink>[
    if (useFirestore) FirestoreAccountDeletionSink() else InMemoryAccountDeletionSink(),
  ];

  if (useFirestore) {
    final appwrite = createAppwriteServices(AppwriteConfig.fromEnvironment);
    if (appwrite != null) {
      sinks.add(
        AppwriteAccountDeletionSink(remote: AppwritePrefsAccountDeletionRemote(appwrite.account)),
      );
    }
  }

  return AccountDeletionRepository(sinks: sinks, flavor: flavor);
});
