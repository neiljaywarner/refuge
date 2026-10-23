import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/presentation/system_insets.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/feedback/presentation/belong_feedback_and_voting_sheet.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openVotingSheet(
    WidgetTester tester, {
    required double paddingBottom,
    required double viewPaddingBottom,
    double viewInsetsBottom = 0,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureVotingBackendTargetProvider.overrideWithValue(
            BackendTarget.inMemory,
          ),
        ],
        child: MaterialApp(
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(top: 24, bottom: paddingBottom),
                viewPadding: media.viewPadding.copyWith(
                  top: 24,
                  bottom: viewPaddingBottom,
                ),
                viewInsets: media.viewInsets.copyWith(bottom: viewInsetsBottom),
              ),
              child: child!,
            );
          },
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () => BelongFeedbackAndVotingSheet.show(context),
                  child: const Text('Open sheet'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'voting sheet keeps bottom viewPadding when MediaQuery.padding is zero',
    (tester) async {
      await openVotingSheet(tester, paddingBottom: 0, viewPaddingBottom: 48);

      final inset = tester.widget<Padding>(
        find.byKey(SystemBottomInset.insetKey),
      );
      expect(inset.padding, const EdgeInsets.only(bottom: 48));

      final sheet = tester.getRect(find.byType(BelongFeedbackAndVotingSheet));
      expect(800 - sheet.bottom, greaterThanOrEqualTo(48));

      final list = tester.widget<ListView>(find.byType(ListView).first);
      expect(list.padding, const EdgeInsets.fromLTRB(16, 16, 16, 24));
    },
  );

  testWidgets('voting sheet does not stack padding and viewPadding', (
    tester,
  ) async {
    await openVotingSheet(tester, paddingBottom: 48, viewPaddingBottom: 48);

    final inset = tester.widget<Padding>(
      find.byKey(SystemBottomInset.insetKey),
    );
    expect(inset.padding, const EdgeInsets.only(bottom: 48));

    final list = tester.widget<ListView>(find.byType(ListView).first);
    expect(list.padding, const EdgeInsets.fromLTRB(16, 16, 16, 24));
  });

  testWidgets(
    'voting sheet uses the keyboard inset without adding the nav bar',
    (tester) async {
      await openVotingSheet(
        tester,
        paddingBottom: 0,
        viewPaddingBottom: 48,
        viewInsetsBottom: 300,
      );

      final inset = tester.widget<Padding>(
        find.byKey(SystemBottomInset.insetKey),
      );
      expect(inset.padding, const EdgeInsets.only(bottom: 300));
    },
  );

  testWidgets(
    'bottom nav keeps one inset and the scaffold body does not add another',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
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
              body: const SafeArea(
                top: false,
                child: SizedBox(key: Key('home_body'), height: 20),
              ),
              bottomNavigationBar: BelongBottomNavBar(
                currentTab: BelongBottomTab.home,
                isContrast: false,
                onSelectTab: (_) {},
              ),
            ),
          ),
        ),
      );

      final bodySafeArea = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(SafeArea),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect((bodySafeArea.padding as EdgeInsets).bottom, 0);

      final navInset = tester.widget<Padding>(
        find
            .descendant(
              of: find.byKey(const Key('belong_bottom_nav_bar')),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(navInset.padding, const EdgeInsets.only(bottom: 48));
    },
  );
}
