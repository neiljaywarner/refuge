import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/account_deletion/data/account_deletion_sinks.dart';
import 'package:refuge4serverpod/src/features/account_deletion/domain/account_deletion_record.dart';
import 'package:refuge4serverpod/src/features/account_deletion/presentation/return_after_delete_panel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolWidgetTest(
    'Patrol: timestamped member deletes, is blocked, then types RESTORE',
    ($) async {
      final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final email = 'tester-patrol-$stamp@example.com';
      final sink = InMemoryAccountDeletionSink();
      final repo = AccountDeletionRepository(sinks: [sink], flavor: 'dev');
      final userId = 'member-$stamp';

      await repo.softDeleteSelf(
        userId: userId,
        displayName: 'Fellow Member',
        email: email,
        confirmed: true,
      );
      expect(await repo.isSignInBlocked(userId), isTrue);
      expect(
        sink.records['dev_$userId']?.profilePatch()['listedInDirectory'],
        isFalse,
      );

      await $.pumpWidget(
        UncontrolledProviderScope(
          container: ProviderContainer(),
          child: MaterialApp(
            home: Scaffold(
              body: ReturnAfterDeletePanel(
                onRestore: () =>
                    repo.restoreSelf(userId: userId, confirmed: true),
                onStayDeleted: () async {},
              ),
            ),
          ),
        ),
      );

      expect(
        $('An organizer cannot turn this back on for you.'),
        findsOneWidget,
      );
      await $(const Key('return_after_delete_field')).enterText('RESTORE');
      await $(const Key('return_after_delete_submit_button')).tap();
      await $.pumpAndSettle();

      expect(await repo.isSignInBlocked(userId), isFalse);
      expect(
        AccountDeletionRecord.directoryRestorePatch(
          DateTime.utc(2026, 10, 25),
        )['listedInDirectory'],
        isTrue,
      );
    },
  );
}
