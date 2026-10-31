import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/fellowship_spaces/domain/fellowship_space.dart';
import 'package:refuge4serverpod/src/features/install/domain/phone_install_links.dart';
import 'package:refuge4serverpod/src/features/install/presentation/phone_install_guide_view.dart';

void main() {
  testWidgets(
    'shows a calm summary, pending stores, and the Android website note',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PhoneInstallGuideView(focus: PhoneInstallFocus.android),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('phone_install_summary')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Firebase is just the Google page'),
        findsOneWidget,
      );
      expect(find.text('Pending'), findsNWidgets(3));
      expect(
        find.byKey(const ValueKey('phone_install_open_beta_button')),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'You only need this if you are testing the website',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Open as Web App'), findsNothing);

      final iosJump = find.byKey(const ValueKey('phone_install_jump_ios_web'));
      await tester.ensureVisible(iosJump);
      await tester.pumpAndSettle();
      await tester.tap(iosJump);
      await tester.pumpAndSettle();
      expect(find.textContaining('Add to Home Screen'), findsOneWidget);
      expect(find.textContaining('Open as Web App'), findsOneWidget);

      expect(find.textContaining('Allow from this source'), findsWidgets);
      expect(
        find.textContaining('If the warning says the app is harmful, stop'),
        findsOneWidget,
      );
    },
  );

  test('phone links open the guide and the stores stay unlinked', () {
    BelongSpaceItem? android;
    BelongSpaceItem? ios;
    for (final section in kBelongSpaceSections) {
      for (final item in section.items) {
        if (item.slug == 'link_android_app') android = item;
        if (item.slug == 'link_ios_app') ios = item;
      }
    }

    expect(android, isNotNull);
    expect(android!.isComingSoon, isFalse);
    expect(android.externalUrl, isNull);
    expect(android.phoneInstallFocus, PhoneInstallFocus.android);
    expect(ios, isNotNull);
    expect(ios!.isComingSoon, isFalse);
    expect(ios.externalUrl, isNull);
    expect(ios.phoneInstallFocus, PhoneInstallFocus.ios);
    expect(
      PhoneInstallLinks.androidBeta,
      'https://appdistribution.firebase.google.com',
    );
  });
}
