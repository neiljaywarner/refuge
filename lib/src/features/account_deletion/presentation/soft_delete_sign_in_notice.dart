import 'package:flutter/material.dart';

/// Calm explanation shown when a deleted account tries to sign in again.
class SoftDeleteSignInNotice extends StatelessWidget {
  const SoftDeleteSignInNotice({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const .only(bottom: 12),
      child: Text(
        text,
        key: const Key('soft_delete_sign_in_blocked'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
