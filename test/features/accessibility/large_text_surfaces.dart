import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/simple_sign_in_screen.dart';
import 'package:refuge4serverpod/src/features/feedback/data/feature_voting_repository.dart';
import 'package:refuge4serverpod/src/features/messages/domain/message_thread.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/belong_messages_view.dart';
import 'package:refuge4serverpod/src/features/notifications/presentation/calm_notification_preferences_sheet.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/threaded_discussion_sheet.dart';

import '../../helpers/text_scale.dart';

Widget _scope(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(overrides: overrides, child: child);

/// Signed-out sign-in wall. Firebase is left uninitialized, which is the
/// widget-test path for this screen.
Future<TextScaleSession> pumpSignInAtScale(WidgetTester tester, double scale) => pumpWithTextScale(
  tester,
  const SimpleSignInScreen(firebaseReady: false),
  scale: scale,
  shell: _scope,
);

Future<TextScaleSession> pumpHomeAtScale(WidgetTester tester, double scale) {
  final repository = LocalPostRepository();
  return pumpWithTextScale(
    tester,
    RefugeHomeScreen(repository: repository),
    scale: scale,
    shell: (child) =>
        _scope(child, overrides: [postRepositoryProvider.overrideWithValue(repository)]),
  );
}

Future<Post> _firstPrayerPost() async {
  final repository = LocalPostRepository();
  final posts = await repository.getPosts(spaceKey: 'prayer');
  return posts.first;
}

Future<TextScaleSession> pumpPostCardAtScale(WidgetTester tester, double scale) async {
  final repository = LocalPostRepository();
  final post = (await repository.getPosts(spaceKey: 'prayer')).first;
  return pumpWithTextScale(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        child: ReflectionCard(post: post, isContrast: false, onAddReaction: (_) {}),
      ),
    ),
    scale: scale,
    shell: (child) =>
        _scope(child, overrides: [postRepositoryProvider.overrideWithValue(repository)]),
  );
}

Future<TextScaleSession> pumpPostDetailAtScale(WidgetTester tester, double scale) async {
  final post = await _firstPrayerPost();
  final session = await pumpWithTextScale(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const Key('open_post_detail'),
            onPressed: () => ThreadedDiscussionSheet.show(context, post: post),
            child: const Text('Open discussion'),
          ),
        ),
      ),
    ),
    scale: scale,
    shell: _scope,
  );
  await tester.tap(find.byKey(const Key('open_post_detail')));
  await settleLargeText(tester);
  session.check();
  return session;
}

Future<TextScaleSession> pumpMessagesAtScale(WidgetTester tester, double scale) =>
    pumpWithTextScale(
      tester,
      BelongMessagesView(initialThreads: MessageThread.sampleThreads()),
      scale: scale,
      shell: _scope,
    );

Future<void> openFirstMessageThread(WidgetTester tester, TextScaleSession session) async {
  final tile = find.byKey(const Key('thread-thread-welcome'));
  await tester.ensureVisible(tile);
  await tester.pump();
  await tester.tap(tile);
  await settleLargeText(tester);
  session.check();
}

Future<TextScaleSession> pumpSensorySettingsAtScale(WidgetTester tester, double scale) async {
  final session = await pumpWithTextScale(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const Key('open_sensory_settings'),
            onPressed: () => showAboutRefugeDialog(
              context,
              primaryColor: const Color(0xFF2D5A27),
              isContrast: false,
            ),
            child: const Text('Settings'),
          ),
        ),
      ),
    ),
    scale: scale,
  );
  await tester.tap(find.byKey(const Key('open_sensory_settings')));
  await settleLargeText(tester);
  session.check();
  return session;
}

Future<TextScaleSession> pumpNotificationSettingsAtScale(WidgetTester tester, double scale) async {
  final session = await pumpWithTextScale(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const Key('open_notification_settings'),
            onPressed: () => CalmNotificationPreferencesSheet.show(context),
            child: const Text('Notification settings'),
          ),
        ),
      ),
    ),
    scale: scale,
    shell: _scope,
  );
  await tester.tap(find.byKey(const Key('open_notification_settings')));
  await settleLargeText(tester);
  session.check();
  return session;
}

Future<TextScaleSession> pumpFeedbackAtScale(WidgetTester tester, double scale) async {
  final session = await pumpWithTextScale(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const Key('open_feedback'),
            onPressed: () => BelongFeedbackAndVotingSheet.show(context),
            child: const Text('Feedback'),
          ),
        ),
      ),
    ),
    scale: scale,
    shell: (child) => _scope(
      child,
      overrides: [featureVotingBackendTargetProvider.overrideWithValue(BackendTarget.inMemory)],
    ),
  );
  await tester.tap(find.byKey(const Key('open_feedback')));
  await settleLargeText(tester);
  session.check();
  return session;
}
