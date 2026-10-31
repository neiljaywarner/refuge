import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/constants/app_theme.dart';
import 'package:refuge4serverpod/src/features/account_deletion/presentation/delete_my_account_dialog.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';

void main() {
  group('Delete Account Button Contrast in Sensory Themes (#691)', () {
    setUp(() {
      ProfileStorageService.instance.clear();
    });

    tearDown(() {
      ProfileStorageService.instance.clear();
    });

    patrolWidgetTest(
      'Delete account button in MemberProfileDialog uses error color in Sage theme',
      ($) async {
        final sageTheme = SensoryThemeData.getTheme(SensoryMode.sage);
        final container = ProviderContainer(
          overrides: [authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory)],
        );
        addTearDown(container.dispose);

        container
            .read(memberProfileProvider.notifier)
            .signIn(
              displayName: 'Sage Member',
              email: 'sage@belongonthespectrum.com',
              bio: 'Exploring Belong on the Spectrum',
              icocChurchAffiliation: 'I am not a member of an ICOC church',
            );

        await $.pumpWidgetAndSettle(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: sageTheme,
              home: const Scaffold(body: MemberProfileDialog()),
            ),
          ),
        );

        final buttonFinder = $(const Key('delete_my_account_button'));
        expect(buttonFinder, findsOneWidget);

        final textButton = $.tester.widget<TextButton>(buttonFinder);
        final foreground = textButton.style?.foregroundColor?.resolve({});
        expect(foreground, equals(sageTheme.colorScheme.error));
        expect(foreground, isNot(equals(Colors.white)));
        expect(foreground, isNot(equals(sageTheme.colorScheme.onError)));
      },
    );

    patrolWidgetTest(
      'DeleteAccountButton wrapped in localized Theme overrides onError to error for text variant',
      ($) async {
        final sageTheme = SensoryThemeData.getTheme(SensoryMode.sage);

        await $.pumpWidgetAndSettle(
          MaterialApp(
            theme: sageTheme,
            home: Scaffold(
              body: Theme(
                data: sageTheme.copyWith(
                  colorScheme: sageTheme.colorScheme.copyWith(onError: sageTheme.colorScheme.error),
                ),
                child: const DeleteAccountButton(
                  key: Key('styled_delete_account_button'),
                  variant: ButtonVariant.text,
                ),
              ),
            ),
          ),
        );

        expect($(const Key('styled_delete_account_button')), findsOneWidget);

        // Find the Text widget inside DeleteAccountButton
        final textWidgets = $.tester.widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('styled_delete_account_button')),
            matching: find.byType(Text),
          ),
        );
        expect(textWidgets, isNotEmpty);
        final labelText = textWidgets.first;
        expect(labelText.style?.color, equals(sageTheme.colorScheme.error));
        expect(labelText.style?.color, isNot(equals(Colors.white)));

        // Find the Icon widget inside DeleteAccountButton
        final iconWidgets = $.tester.widgetList<Icon>(
          find.descendant(
            of: find.byKey(const Key('styled_delete_account_button')),
            matching: find.byType(Icon),
          ),
        );
        expect(iconWidgets, isNotEmpty);
        final icon = iconWidgets.first;
        expect(icon.color, equals(sageTheme.colorScheme.error));
        expect(icon.color, isNot(equals(Colors.white)));
      },
    );

    patrolWidgetTest(
      'DeleteMyAccountDialog confirmation button uses error color for clear destructive affordance',
      ($) async {
        final sageTheme = SensoryThemeData.getTheme(SensoryMode.sage);
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await $.pumpWidgetAndSettle(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: sageTheme,
              home: const Scaffold(body: DeleteMyAccountDialog()),
            ),
          ),
        );

        final submitFinder = $(const Key('delete_my_account_submit_button'));
        expect(submitFinder, findsOneWidget);

        final filledButton = $.tester.widget<FilledButton>(submitFinder);
        final bg = filledButton.style?.backgroundColor?.resolve({});
        final fg = filledButton.style?.foregroundColor?.resolve({});

        expect(bg, equals(sageTheme.colorScheme.error));
        expect(fg, equals(sageTheme.colorScheme.onError));
      },
    );
  });
}
