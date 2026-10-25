import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../domain/message_recipient.dart';
import 'direct_message_mailbox.dart';

/// When false, the picker uses only real directory rows (widget tests).
final messageRecipientIncludeSamplesProvider = Provider<bool>((ref) => true);

final directMessageMailboxProvider = Provider<DirectMessageMailbox>((ref) {
  final flavor = ref.watch(appFlavorProvider);
  final override = ref.watch(directMessageMailboxOverrideProvider);
  if (override != null) return override;
  return createDirectMessageMailbox(flavor: flavor);
});

/// Test override for an in-memory mailbox.
final directMessageMailboxOverrideProvider = Provider<DirectMessageMailbox?>(
  (ref) => null,
);

final messageRecipientDirectoryProvider =
    FutureProvider<List<MessageRecipient>>((ref) async {
      final mailbox = ref.watch(directMessageMailboxProvider);
      final flavor = ref.watch(appFlavorProvider);
      final includeSamples = ref.watch(messageRecipientIncludeSamplesProvider);
      return mailbox.loadDirectory(
        includeSamples: includeSamples,
        isProduction: flavor.isProduction,
      );
    });
