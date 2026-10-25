import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_provider.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_sinks.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_exception.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_record.dart';
import 'package:refuge4serverpod/src/features/account_deletion/presentation/return_after_delete_panel.dart';
import 'package:refuge4serverpod/src/features/account_deletion/presentation/soft_delete_sign_in_notice.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';

void main() {
  patrolWidgetTest(
    'Scenario: the member who just deleted can type RESTORE and sign in',
    ($) async {
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final email = 'tester-$stamp@example.com';
      final sink = InMemoryAccountDeletionSink();
      final repo = AccountDeletionRepository(sinks: [sink], flavor: 'dev');
      final container = ProviderContainer(
        overrides: [
          authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
          accountDeletionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final auth = container.read(authRepositoryProvider);
      await auth.registerWithPassword(
        email: email,
        password: 'password1',
        displayName: 'Fellow Member',
        icocChurchAffiliation: 'Chicago Church of Christ',
      );
      final userId = auth.currentSession().userId;
      await repo.softDeleteSelf(
        userId: userId,
        displayName: 'Fellow Member',
        email: email,
        confirmed: true,
      );
      await auth.signOut();
      expect(await repo.isSignInBlocked(userId), isTrue);

      await $.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReturnAfterDeletePanel(
              onRestore: () =>
                  repo.restoreSelf(userId: userId, confirmed: true),
              onStayDeleted: () async {},
            ),
          ),
        ),
      );

      await $(const Key('return_after_delete_field')).enterText('nope');
      await $(const Key('return_after_delete_submit_button')).tap();
      expect(
        $(AccountDeletionMessages.restoreConfirmationRequired),
        findsOneWidget,
      );
      expect(await repo.isSignInBlocked(userId), isTrue);

      await $(const Key('return_after_delete_field')).enterText('RESTORE');
      await $(const Key('return_after_delete_submit_button')).tap();
      await $.pumpAndSettle();

      expect(await repo.isSignInBlocked(userId), isFalse);
      final session = await auth.signInWithPassword(
        email: email,
        password: 'password1',
      );
      expect(session.isSignedIn, isTrue);
      expect(session.email, email);
    },
  );

  patrolWidgetTest(
    'Scenario: the blocked notice has no organizer restore control',
    ($) async {
      await $.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SoftDeleteSignInNotice(
              message: AccountDeletionMessages.signInBlocked,
            ),
          ),
        ),
      );

      expect($(const Key('soft_delete_sign_in_blocked')), findsOneWidget);
      expect($(const Key('return_after_delete_submit_button')), findsNothing);
      expect($('Come back'), findsNothing);
    },
  );
}
