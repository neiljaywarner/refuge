import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:refuge4serverpod/main.dart';

/// Read-only Patrol harness: local posts, guest profile, no sign-in wall.
///
/// [extraOverrides] inject fakes (for example a Giphy search double) without
/// signing in or writing a member feed.
Future<void> pumpDevReadOnlyHome(
  PatrolIntegrationTester $, {
  List<Override> extraOverrides = const [],
}) async {
  $.tester.view.devicePixelRatio = 1.0;
  $.tester.view.physicalSize = const Size(390, 844);
  addTearDown(() {
    $.tester.view.resetPhysicalSize();
    $.tester.view.resetDevicePixelRatio();
  });

  await $.pumpWidgetAndSettle(
    RefugeApp(
      repository: LocalPostRepository(isDevMode: true),
      enforceSignIn: false,
      overrides: [memberProfileProvider.overrideWith(_GuestProfile.new), ...extraOverrides],
    ),
  );
}

class _GuestProfile extends MemberProfileNotifier {
  @override
  MemberProfile build() => const MemberProfile.guest();
}
