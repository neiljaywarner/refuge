import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/core/presentation/system_insets.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openVotingSheet(
    PatrolTester $, {
    required double paddingBottom,
    required double viewPaddingBottom,
    double viewInsetsBottom = 0,
  }) async {
    $.tester.view.physicalSize = const Size(400, 800);
    $.tester.view.devicePixelRatio = 1;
    addTearDown($.tester.view.resetPhysicalSize);
    addTearDown($.tester.view.resetDevicePixelRatio);

    await $.pumpWidget(
      ProviderScope(
        overrides: [featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory)],
        child: MaterialApp(
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(top: 24, bottom: paddingBottom),
                viewPadding: media.viewPadding.copyWith(top: 24, bottom: viewPaddingBottom),
                viewInsets: media.viewInsets.copyWith(bottom: viewInsetsBottom),
              ),
              child: child!,
            );
          },
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => BelongFeedbackAndVotingSheet.show(context),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await $('Open sheet').tap();
    await $.pumpAndSettle();
  }

  patrolWidgetTest('The feedback sheet clears the Android navigation bar', ($) async {
    // Given the Android navigation bar is 48 pixels
    // And the sheet's own bottom padding is empty
    // When a member opens Vote on Features
    await openVotingSheet($, paddingBottom: 0, viewPaddingBottom: 48);

    // Then the sheet sits above the navigation bar
    final inset = $.tester.widget<Padding>(find.byKey(SystemBottomInset.insetKey));
    expect(inset.padding, const EdgeInsets.only(bottom: 48));

    final sheet = $.tester.getRect(find.byType(BelongFeedbackAndVotingSheet));
    expect(800 - sheet.bottom, greaterThanOrEqualTo(48));

    // And the list inside the sheet keeps its own spacing
    final list = $.tester.widget<ListView>(find.byType(ListView).first);
    expect(list.padding, const EdgeInsets.fromLTRB(16, 16, 16, 24));
  });

  patrolWidgetTest('The feedback sheet does not add the navigation bar twice', ($) async {
    // Given the navigation bar is already counted once
    // When a member opens Vote on Features
    await openVotingSheet($, paddingBottom: 48, viewPaddingBottom: 48);

    // Then the sheet adds that bar only once
    final inset = $.tester.widget<Padding>(find.byKey(SystemBottomInset.insetKey));
    expect(inset.padding, const EdgeInsets.only(bottom: 48));

    // And the list inside the sheet keeps its own spacing
    final list = $.tester.widget<ListView>(find.byType(ListView).first);
    expect(list.padding, const EdgeInsets.fromLTRB(16, 16, 16, 24));
  });

  patrolWidgetTest(
    'The feedback sheet uses the keyboard space and does not also add the navigation bar',
    ($) async {
      // Given the keyboard is open and the navigation bar is behind it
      // When a member opens Vote on Features
      await openVotingSheet($, paddingBottom: 0, viewPaddingBottom: 48, viewInsetsBottom: 300);

      // Then the sheet uses the keyboard space
      // And it does not add the navigation bar on top of the keyboard
      final inset = $.tester.widget<Padding>(find.byKey(SystemBottomInset.insetKey));
      expect(inset.padding, const EdgeInsets.only(bottom: 300));
    },
  );

  patrolWidgetTest('The home bottom bar keeps one inset and the page body does not add another', (
    $,
  ) async {
    // Given the home screen has a bottom navigation bar
    // And the system navigation bar is 48 pixels while the page padding is 0
    $.tester.view.physicalSize = const Size(400, 800);
    $.tester.view.devicePixelRatio = 1;
    addTearDown($.tester.view.resetPhysicalSize);
    addTearDown($.tester.view.resetDevicePixelRatio);

    // When the page is shown
    await $.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: SystemInsets.repairPadding(
                media.copyWith(
                  padding: media.padding.copyWith(bottom: 0),
                  viewPadding: media.viewPadding.copyWith(bottom: 48),
                ),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: const SafeArea(top: false, child: SizedBox(key: Key('home_body'), height: 20)),
            bottomNavigationBar: BelongBottomNavBar(
              currentTab: BelongBottomTab.home,
              isContrast: false,
              onSelectTab: (_) {},
            ),
          ),
        ),
      ),
    );

    // Then the page body does not add a second gap
    final bodySafeArea = $.tester.widget<Padding>(
      find.descendant(of: find.byType(SafeArea), matching: find.byType(Padding)).first,
    );
    expect((bodySafeArea.padding as EdgeInsets).bottom, 0);

    // And the bottom bar clears the system bar once
    final navInset = $.tester.widget<Padding>(
      find
          .descendant(
            of: find.byKey(const Key('belong_bottom_nav_bar')),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(navInset.padding, const EdgeInsets.only(bottom: 48));
  });
}
