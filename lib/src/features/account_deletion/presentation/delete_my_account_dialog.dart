import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../profile/domain/member_profile.dart';
import '../domain/account_deletion_exception.dart';

/// Confirms a self-service soft delete. The member must type DELETE.
class DeleteMyAccountDialog extends HookConsumerWidget {
  const DeleteMyAccountDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const DeleteMyAccountDialog(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phrase = useTextEditingController();
    final errorText = useState<String?>(null);
    final submitting = useState(false);

    Future<void> submit() async {
      if (phrase.text.trim() != AccountDeletionMessages.confirmationPhrase) {
        errorText.value = AccountDeletionMessages.confirmationRequired;
        return;
      }
      submitting.value = true;
      errorText.value = null;
      try {
        await ref.read(memberProfileProvider.notifier).deleteMyAccount();
        if (!context.mounted) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
        if (navigator.canPop()) navigator.pop();
      } on AccountDeletionException catch (error) {
        if (!context.mounted) return;
        errorText.value = error.message;
        submitting.value = false;
      } catch (_) {
        if (!context.mounted) return;
        errorText.value = AccountDeletionMessages.backendFailed;
        submitting.value = false;
      }
    }

    return AlertDialog(
      title: const Text('Delete my account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AccountDeletionMessages.deleteExplanation),
          const SizedBox(height: 12),
          TextField(
            key: const Key('delete_my_account_confirm_field'),
            controller: phrase,
            enabled: !submitting.value,
            decoration: const InputDecoration(
              labelText: 'Type DELETE to confirm',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
          ),
          if (errorText.value != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText.value!,
              key: const Key('delete_my_account_error_text'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('delete_my_account_cancel_button'),
          onPressed: submitting.value
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('delete_my_account_submit_button'),
          onPressed: submitting.value ? null : submit,
          child: const Text('Delete account'),
        ),
      ],
    );
  }
}
