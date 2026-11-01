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
  // A Pixel 7 (panther) is already ~412 dp wide. Forcing 390x844 at
  // devicePixelRatio 1 detaches Flutter's surface from that window: the
  // widget tree still builds (finders pass) but the device keeps Patrol's
  // first frame, and taps hit the wrong control.
  // Desktop-width emulators still get a phone frame so the inline composer
  // stays on screen (it hides at width >= 768).
  await $.pump();
  final view = $.tester.view;
  final dpr = view.devicePixelRatio == 0 ? 1.0 : view.devicePixelRatio;
  final logicalWidth = view.physicalSize.width / dpr;
  if (logicalWidth >= 768) {
    view.devicePixelRatio = 1.0;
    view.physicalSize = const Size(390, 844);
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  }

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
