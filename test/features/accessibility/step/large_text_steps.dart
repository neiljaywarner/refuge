import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/text_scale.dart';
import '../large_text_surfaces.dart';
import 'large_text_world.dart';

Future<void> theSignInWallIsShownAtLargeTextScales(WidgetTester tester) async {
  largeTextWorld = LargeTextWorld(tester);
  for (final scale in largeTextScales) {
    largeTextWorld!.session = await pumpSignInAtScale(tester, scale);
    expect(find.byKey(const Key('sign_in_title')), findsOneWidget);
    largeTextWorld!.sawSignInTitle = true;
  }
}

Future<void> theSignInTitleIsVisible(WidgetTester tester) async {
  expect(largeTextWorld!.sawSignInTitle, isTrue);
  expect(find.byKey(const Key('sign_in_title')), findsOneWidget);
}

Future<void> theForgotPasswordControlIsTappable(WidgetTester tester) async {
  final finder = find.byKey(const Key('sign_in_forgot_password'));
  await tester.ensureVisible(finder);
  await tester.pump();
  expectMinTapTarget(tester, finder);
}

Future<void> noTextOverflowIsReported(WidgetTester tester) async {
  largeTextWorld!.session?.check();
}

Future<void> theHomeFeedIsShownAtLargeTextScales(WidgetTester tester) async {
  largeTextWorld = LargeTextWorld(tester);
  for (final scale in largeTextScales) {
    largeTextWorld!.session = await pumpHomeAtScale(tester, scale);
    expect(find.text('Belong'), findsWidgets);
    expect(find.byKey(const Key('bottom_nav_tab_home')), findsOneWidget);
    largeTextWorld!.sawHome = true;
  }
}

Future<void> belongAndTheHomeTabAreVisible(WidgetTester tester) async {
  expect(largeTextWorld!.sawHome, isTrue);
  expect(find.text('Belong'), findsWidgets);
  expect(find.byKey(const Key('bottom_nav_tab_home')), findsOneWidget);
}

Future<void> theHomeTabIsTappable(WidgetTester tester) async {
  expectMinTapTarget(tester, find.byKey(const Key('bottom_nav_tab_home')));
}

Future<void> aReflectionCardIsShownAtLargeTextScales(WidgetTester tester) async {
  largeTextWorld = LargeTextWorld(tester);
  for (final scale in largeTextScales) {
    largeTextWorld!.session = await pumpPostCardAtScale(tester, scale);
    expect(find.byKey(const Key('author_tap_target_1')), findsOneWidget);
  }
}

Future<void> theDiscussionIsOpenAtLargeTextScales(WidgetTester tester) async {
  for (final scale in largeTextScales) {
    largeTextWorld!.session = await pumpPostDetailAtScale(tester, scale);
    expect(find.byKey(const Key('threaded_discussion_sheet_title')), findsOneWidget);
    largeTextWorld!.sawDiscussion = true;
  }
}

Future<void> theDiscussionTitleIsVisible(WidgetTester tester) async {
  expect(largeTextWorld!.sawDiscussion, isTrue);
  expect(find.text('Discussion & Replies'), findsOneWidget);
}

Future<void> aDirectMessageThreadIsOpenAtLargeTextScales(WidgetTester tester) async {
  largeTextWorld = LargeTextWorld(tester);
  for (final scale in largeTextScales) {
    largeTextWorld!.session = await pumpMessagesAtScale(tester, scale);
    expect(find.text('Direct Messages'), findsOneWidget);
    await openFirstMessageThread(tester, largeTextWorld!.session!);
    expect(find.text('Marty & Community Team'), findsWidgets);
    largeTextWorld!.sawMessages = true;
  }
}

Future<void> theMessageTitleIsVisible(WidgetTester tester) async {
  expect(largeTextWorld!.sawMessages, isTrue);
  expect(find.text('Marty & Community Team'), findsWidgets);
}

Future<void> sensorySettingsAreOpenAtLargeTextScales(WidgetTester tester) async {
  largeTextWorld = LargeTextWorld(tester);
  for (final scale in largeTextScales) {
    largeTextWorld!.session = await pumpSensorySettingsAtScale(tester, scale);
    expect(find.text('Standard (100%)'), findsOneWidget);
    largeTextWorld!.sawFontChoices = true;
  }
}

Future<void> notificationSettingsAreOpenAtLargeTextScales(WidgetTester tester) async {
  for (final scale in largeTextScales) {
    largeTextWorld!.session = await pumpNotificationSettingsAtScale(tester, scale);
    expect(find.text('Calm Notification Ethics'), findsOneWidget);
  }
}

Future<void> theFontScalingChoicesAreVisible(WidgetTester tester) async {
  expect(largeTextWorld!.sawFontChoices, isTrue);
}

Future<void> theFeedbackSheetIsOpenAtLargeTextScales(WidgetTester tester) async {
  largeTextWorld = LargeTextWorld(tester);
  for (final scale in largeTextScales) {
    largeTextWorld!.session = await pumpFeedbackAtScale(tester, scale);
    expect(find.text('Belong Roadmap & Feedback'), findsOneWidget);
    largeTextWorld!.sawFeedback = true;
  }
}

Future<void> theFeedbackTitleIsVisible(WidgetTester tester) async {
  expect(largeTextWorld!.sawFeedback, isTrue);
  expect(find.text('Belong Roadmap & Feedback'), findsOneWidget);
}
