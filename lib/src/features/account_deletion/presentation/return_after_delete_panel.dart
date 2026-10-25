import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../domain/account_deletion_exception.dart';

/// Shown after the same member proves they still hold the password.
///
/// An organizer does not get this control. Typing [AccountDeletionMessages.restorePhrase]
/// is the member's own choice to come back. See discussion #590.
class ReturnAfterDeletePanel extends HookWidget {
  const ReturnAfterDeletePanel({super.key, required this.onRestore, required this.onStayDeleted});

  final Future<void> Function() onRestore;
  final Future<void> Function() onStayDeleted;

  @override
  Widget build(BuildContext context) {
    final phrase = useTextEditingController();
    final errorText = useState<String?>(null);
    final submitting = useState(false);

    Future<void> submit() async {
      if (phrase.text.trim() != AccountDeletionMessages.restorePhrase) {
        errorText.value = AccountDeletionMessages.restoreConfirmationRequired;
        return;
      }
      submitting.value = true;
      errorText.value = null;
      try {
        await onRestore();
      } on AccountDeletionException catch (error) {
        errorText.value = error.message;
        submitting.value = false;
      } catch (_) {
        errorText.value = AccountDeletionMessages.backendFailed;
        submitting.value = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AccountDeletionMessages.returnExplanation,
            key: const Key('return_after_delete_explanation'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('return_after_delete_field'),
            controller: phrase,
            enabled: !submitting.value,
            decoration: const InputDecoration(
              labelText: 'Type RESTORE to come back',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
          ),
          if (errorText.value != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText.value!,
              key: const Key('return_after_delete_error_text'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('return_after_delete_submit_button'),
            onPressed: submitting.value ? null : submit,
            child: const Text('Come back'),
          ),
          TextButton(
            key: const Key('return_after_delete_stay_deleted_button'),
            onPressed: submitting.value ? null : onStayDeleted,
            child: const Text('Stay deleted'),
          ),
        ],
      ),
    );
  }
}
