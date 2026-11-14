import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/belong_messages_view.dart';
import 'package:refuge4serverpod/src/features/navigation/presentation/belong_bottom_nav_bar.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/notifications_controller.dart';
import 'package:refuge4serverpod/src/features/reflections/data/local_post_repository.dart';
import 'package:refuge4serverpod/src/features/reflections/data/post_repository.dart';
import 'package:refuge4serverpod/src/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/text_scale.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a notification target opens messages, then a space on the feed', (tester) async {
    final repository = LocalPostRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: RefugeHomeScreen(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(RefugeHomeScreen)));
    container
        .read(notificationNavigationTargetProvider.notifier)
        .state = const NotificationNavigationTarget(
      tab: BelongBottomTab.msgs,
      conversationId: 'thread-welcome',
    );
    await tester.pumpAndSettle();

    expect(find.byType(BelongMessagesView), findsOneWidget);
    expect(container.read(notificationNavigationTargetProvider), isNull);

    container
        .read(notificationNavigationTargetProvider.notifier)
        .state = const NotificationNavigationTarget(
      tab: BelongBottomTab.home,
      spaceKey: 'prayer',
      postId: 'missing-post',
    );
    await tester.pumpAndSettle();
    expect(find.byType(BelongMessagesView), findsNothing);
    expect(find.text('Belong'), findsWidgets);
  });

  testWidgets('home at text scale 2 opens Spaces from the feed', (tester) async {
    final repository = LocalPostRepository();
    final session = await pumpWithTextScale(
      tester,
      RefugeHomeScreen(repository: repository),
      scale: 2,
      shell: (child) => ProviderScope(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
        child: child,
      ),
    );

    expect(find.byKey(const Key('subnav_spaces_tab')), findsOneWidget);
    await tester.tap(find.byKey(const Key('subnav_spaces_tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('belong_spaces_directory_list')), findsOneWidget);
    session.check();
  });
}
