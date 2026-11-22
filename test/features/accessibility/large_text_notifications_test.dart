import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/calm_notifications_view.dart';
import 'package:refuge4serverpod/src/features/notifications/data/app_launcher_badge_service.dart';
import 'package:refuge4serverpod/src/features/notifications/domain/belong_notification.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';

import '../../helpers/text_scale.dart';

/// Keeps the bell quiet. The view still lays out every filter and the title.
class _QuietBadge extends AppLauncherBadgeService {
  @override
  Future<bool> setBadgeCount(int count) async => true;
}

const _filterChipKeys = <String>[
  'filter_chip_inbox',
  'filter_chip_mentions',
  'filter_chip_directMessages',
  'filter_chip_threads',
  'filter_chip_following',
];

/// Phone surface and text scaler from [pumpWithTextScale], without that
/// helper's overflow capture.
///
/// The capture treats any later [TestFailure] whose message quotes an
/// "overflowed" layout error as another overflow and swallows it, so the test
/// never finishes. Layout errors are taken below and checked after the
/// visible-content assertions.
Future<void> _pumpNotifications(
  WidgetTester tester,
  double scale, {
  Size surface = largeTextPhoneSurface,
  List<BelongNotification> notices = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = surface;
  final dispatcher = tester.platformDispatcher;
  dispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    dispatcher.clearTextScaleFactorTestValue();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        belongNotificationsProvider.overrideWith(
          () => BelongNotificationsNotifier(
            initialList: notices,
            badgeService: _QuietBadge(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(scale)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const CalmNotificationsView(),
      ),
    ),
  );
  await settleLargeText(tester);
}

/// Every filter is on the first phone frame. A horizontal scroller that hides
/// a chip to the right fails this without a drag.
void _expectFilterChipsOnFirstFrame(WidgetTester tester) {
  final view = Offset.zero & largeTextPhoneSurface;
  for (final keyName in _filterChipKeys) {
    final finder = find.byKey(Key(keyName));
    expect(finder, findsOneWidget, reason: keyName);
    final rect = tester.getRect(finder);
    expect(
      rect.left,
      greaterThanOrEqualTo(-0.5),
      reason: '$keyName starts off the first frame ($rect)',
    );
    expect(
      rect.top,
      greaterThanOrEqualTo(-0.5),
      reason: '$keyName starts off the first frame ($rect)',
    );
    expect(
      rect.right,
      lessThanOrEqualTo(view.width + 0.5),
      reason: '$keyName needs a horizontal drag ($rect)',
    );
    expect(
      rect.bottom,
      lessThanOrEqualTo(view.height + 0.5),
      reason: '$keyName is below the first frame ($rect)',
    );
    expect(
      finder.hitTestable(),
      findsOneWidget,
      reason: '$keyName is not hittable',
    );
  }
}

/// The app bar paints the whole word. DefaultTextStyle ellipsizes a squeezed
/// title to "Not…" while the [Text] data stays "Notifications".
void _expectReadableNotificationsTitle(WidgetTester tester) {
  final title = find.descendant(
    of: find.byType(AppBar),
    matching: find.text('Notifications'),
  );
  expect(title, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(title);
  expect(paragraph.text.toPlainText(), 'Notifications');
  expect(
    paragraph.didExceedMaxLines,
    isFalse,
    reason: 'app bar title is ellipsized',
  );

  final full = TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    maxLines: 1,
  )..layout(maxWidth: double.infinity);
  expect(
    full.width,
    lessThanOrEqualTo(paragraph.size.width + 0.5),
    reason:
        'Notifications needs ${full.width} px but the app bar painted ${paragraph.size.width} px',
  );
  full.dispose();

  final rect = tester.getRect(title);
  expect(rect.left, greaterThanOrEqualTo(-0.5));
  expect(rect.top, greaterThanOrEqualTo(-0.5));
  expect(rect.right, lessThanOrEqualTo(largeTextPhoneSurface.width + 0.5));
  expect(rect.bottom, lessThanOrEqualTo(largeTextPhoneSurface.height + 0.5));
  expect(rect.width, greaterThan(48));
  expect(rect.height, greaterThan(16));
}

void main() {
  testWidgets(
    'notification filters and title stay readable at text scales 2 and 3',
    (tester) async {
      for (final scale in <double>[2, 3]) {
        await _pumpNotifications(tester, scale);
        final layoutErrors = <Object>[];
        while (true) {
          final error = tester.takeException();
          if (error == null) break;
          layoutErrors.add(error);
        }

        _expectFilterChipsOnFirstFrame(tester);
        _expectReadableNotificationsTitle(tester);
        expect(find.byKey(const Key('mark_all_read_checkbox')), findsOneWidget);
        expect(
          find.byKey(const Key('mark_all_notifications_as_read_button')),
          findsOneWidget,
        );
        expect(
          layoutErrors,
          isEmpty,
          reason: 'text scale $scale: $layoutErrors',
        );
      }
    },
  );

  testWidgets(
    'first notification stays reachable on a short screen at text scales 2 and 3',
    (tester) async {
      const surface = Size(568, 320);
      final notice = BelongNotification(
        id: 'compact-1',
        type: BelongNotificationType.like,
        authorName: 'Fellow Member',
        postTitle: 'A quiet note',
        timestamp: DateTime.utc(2026, 10, 22, 15),
      );
      final tile = find.byKey(const Key('notification_list_tile_compact-1'));

      for (final scale in <double>[2, 3]) {
        await _pumpNotifications(
          tester,
          scale,
          surface: surface,
          notices: [notice],
        );
        final layoutErrors = <Object>[];
        while (true) {
          final error = tester.takeException();
          if (error == null) break;
          layoutErrors.add(error);
        }
        expect(
          layoutErrors,
          isEmpty,
          reason: 'text scale $scale: $layoutErrors',
        );

        await tester.scrollUntilVisible(tile, 200);
        await tester.pump();
        expect(tile, findsOneWidget);
        final rect = tester.getRect(tile);
        expect(rect.bottom, greaterThan(0));
        expect(rect.top, lessThan(surface.height));
      }
    },
  );
}
