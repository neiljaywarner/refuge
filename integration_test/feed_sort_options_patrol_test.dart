import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_option.dart';

class _GuestProfile extends MemberProfileNotifier {
  @override
  MemberProfile build() => const MemberProfile.guest();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolWidgetTest(
    'Patrol: every sort option and tone filter on the demo feed stays mounted',
    ($) async {
      $.tester.view.devicePixelRatio = 1.0;
      $.tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        $.tester.view.resetPhysicalSize();
        $.tester.view.resetDevicePixelRatio();
      });

      await $.pumpWidgetAndSettle(
        RefugeApp(
          repository: LocalPostRepository(isDevMode: true),
          initialTheme: SensoryMode.charcoal,
          overrides: [memberProfileProvider.overrideWith(_GuestProfile.new)],
          homeOverride: const RefugeHomeScreen(),
        ),
      );

      expect(find.textContaining('Demo Mode'), findsOneWidget);

      for (final option in FeedSortOption.values) {
        final key = Key('feed_sort_chip_${option.name}');
        await $.tester.ensureVisible(find.byKey(key));
        await $.tester.tap(find.byKey(key));
        await $.tester.tap(find.byKey(key));
        await $.pumpAndSettle();
        expect($.tester.takeException(), isNull);
        expect($.tester.widget<ChoiceChip>(find.byKey(key)).selected, isTrue);
      }

      for (final filter in kToneFilters) {
        final key = Key(toneFilterSemanticsId(filter));
        await $.tester.ensureVisible(find.byKey(key));
        await $.tester.tap(find.byKey(key));
        await $.pumpAndSettle();
        expect($.tester.takeException(), isNull);
      }

      await $.tester.tap(find.byKey(const Key('feed_sort_popup_button')));
      await $.pumpAndSettle();
      await $.tester.tap(
        find.byKey(const Key('feed_sort_menu_item_newActivity')),
      );
      await $.pumpAndSettle();
      expect(
        $.tester
            .widget<ChoiceChip>(
              find.byKey(const Key('feed_sort_chip_newActivity')),
            )
            .selected,
        isTrue,
      );
    },
  );
}
