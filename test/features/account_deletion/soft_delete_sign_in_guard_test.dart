import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_exception.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/soft_delete_sign_in_guard.dart';

void main() {
  test(
    'blocks sign-in when the tombstone says the account is deleted',
    () async {
      final message = await softDeleteSignInBlockMessage(
        userId: 'member-1',
        isBlocked: (_) async => true,
      );
      expect(message, AccountDeletionMessages.signInBlocked);
    },
  );

  test('allows sign-in when the account is still active', () async {
    final message = await softDeleteSignInBlockMessage(
      userId: 'member-1',
      isBlocked: (_) async => false,
    );
    expect(message, isNull);
  });

  test('ignores an empty user id', () async {
    var calls = 0;
    final message = await softDeleteSignInBlockMessage(
      userId: '  ',
      isBlocked: (_) async {
        calls += 1;
        return true;
      },
    );
    expect(message, isNull);
    expect(calls, 0);
  });
}
