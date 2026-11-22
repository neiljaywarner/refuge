import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/constants/app_theme.dart';
import 'package:refuge4serverpod/src/features/auth/data/auth_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/profile/data/profile_storage_service.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';
import 'package:refuge4serverpod/src/features/profile/presentation/member_profile_sheet.dart';
import 'package:refuge4serverpod/src/features/sensory_themes/domain/sensory_mode.dart';

import '../../helpers/keyboard_visibility.dart';
import '../../support/test_font_loader.dart';

const _fields = <Key>[
  Key('profile_display_name_field'),
  Key('profile_last_name_field'),
  Key('profile_email_field'),
  Key('profile_church_affiliation_dropdown'),
  Key('profile_bio_field'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TestFontLoader.loadAppFonts();
  });

  setUp(() {
    ProfileStorageService.instance.clear();
  });

  tearDown(() {
    ProfileStorageService.instance.clear();
  });

  for (final surface in keyboardPhoneSurfaces) {
    for (final scale in const <double>[1.0, 2.0]) {
      testWidgets(
        'signed-in profile fields and Save stay above the keyboard on ${surface.$1} '
        'at text scale $scale',
        (tester) async {
          final inset = surface.$3;
          final overflows = captureOverflowErrors();
          final container = await _pumpSignedInProfile(
            tester,
            logicalSize: surface.$2,
            textScale: scale,
            keyboardInset: inset,
          );
          addTearDown(container.dispose);
          _expectNoAccountSection();
          expectNoOverflow(overflows, '${surface.$1} scale $scale after open');

          final scrollable = find.descendant(
            of: find.byKey(const Key('profile_sheet_scroll')),
            matching: find.byType(Scrollable),
          );
          for (final key in _fields) {
            final reason = '${surface.$1} scale $scale $key';
            await expectFocusedFieldAboveKeyboard(
              tester,
              field: find.byKey(key, skipOffstage: false),
              pinned: find.byKey(const Key('profile_save_sign_in_button')),
              keyboardInset: inset,
              reason: reason,
              scrollable: scrollable.first,
            );
            expectNoOverflow(overflows, reason);
          }
          expect(container.read(memberProfileProvider).isSignedIn, isTrue);
        },
      );
    }
  }

  testWidgets('account overflow menu signs out without a confirm dialog', (
    tester,
  ) async {
    final container = await _pumpSignedInProfile(
      tester,
      logicalSize: const Size(411, 914),
      textScale: 1,
      keyboardInset: 0,
    );
    addTearDown(container.dispose);

    expect(find.text('Sign Out'), findsNothing);
    expect(find.text('Delete account'), findsNothing);
    await tester.tap(find.byKey(const Key('profile_account_menu_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile_sign_out_button')), findsOneWidget);
    expect(find.byKey(const Key('delete_my_account_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_sign_out_button')));
    await tester.pumpAndSettle();

    expect(container.read(memberProfileProvider).isSignedIn, isFalse);
    expect(find.byKey(const Key('profile_save_sign_in_button')), findsNothing);
    expect(find.text('Are you sure?'), findsNothing);
  });

  testWidgets('delete confirmation Cancel does not delete the account', (
    tester,
  ) async {
    final container = await _pumpSignedInProfile(
      tester,
      logicalSize: const Size(411, 914),
      textScale: 1,
      keyboardInset: 0,
    );
    addTearDown(container.dispose);

    await tester.tap(find.byKey(const Key('profile_account_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_my_account_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('profile_delete_confirm_dialog')),
      findsOneWidget,
    );
    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    final deleteButton = tester.widget<FilledButton>(
      find.byKey(const Key('profile_delete_confirm_delete')),
    );
    final background = deleteButton.style?.backgroundColor?.resolve(
      const <WidgetState>{},
    );
    expect(
      background,
      Theme.of(tester.element(find.text('Are you sure?'))).colorScheme.error,
    );

    await tester.tap(find.byKey(const Key('profile_delete_confirm_cancel')));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure?'), findsNothing);
    expect(
      find.byKey(const Key('delete_my_account_confirm_field')),
      findsNothing,
    );
    expect(container.read(memberProfileProvider).isSignedIn, isTrue);
    expect(
      find.byKey(const Key('profile_save_sign_in_button')),
      findsOneWidget,
    );
  });
}

void _expectNoAccountSection() {
  expect(find.text('Account'), findsNothing);
  expect(find.text('Sign Out'), findsNothing);
  expect(find.text('Delete account'), findsNothing);
}

Future<ProviderContainer> _pumpSignedInProfile(
  WidgetTester tester, {
  required Size logicalSize,
  required double textScale,
  required double keyboardInset,
}) async {
  prepareKeyboardSurface(
    tester,
    logicalSize: logicalSize,
    textScale: textScale,
    keyboardInset: keyboardInset,
  );

  final container = ProviderContainer(
    overrides: [
      authBackendTargetProvider.overrideWithValue(BackendTarget.inMemory),
    ],
  );
  container
      .read(memberProfileProvider.notifier)
      .signIn(
        displayName: 'Fellow Member',
        email: '',
        bio: 'A quiet note',
        icocChurchAffiliation: 'Example Fellowship',
      );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: SensoryThemeData.getTheme(SensoryMode.clean),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(textScale)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Builder(
            builder: (context) => Align(
              alignment: Alignment.topCenter,
              child: IconButton(
                key: const Key('open_profile_sheet'),
                tooltip: 'Open profile',
                onPressed: () => MemberProfileDialog.show(context),
                icon: const Icon(Icons.person_outline),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const Key('open_profile_sheet')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return container;
}
