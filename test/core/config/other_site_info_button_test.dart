import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/core/config/other_site_info_button.dart';

void main() {
  test('dev notice points at the public site', () {
    final notice = OtherSiteNotice.forFlavor(AppFlavor.dev);
    expect(notice.message, contains('You are on the development site'));
    expect(
      notice.message,
      contains('https://dev-belongonthespectrum.web.app/'),
    );
    expect(notice.message, contains('The public site is'));
    expect(notice.message, contains('https://belongonthespectrum.web.app/'));
  });

  test('prod notice points at the development site', () {
    final notice = OtherSiteNotice.forFlavor(AppFlavor.prod);
    expect(notice.message, contains('You are on the public site'));
    expect(notice.message, contains('The development site is'));
    expect(
      notice.message,
      contains('https://dev-belongonthespectrum.web.app/'),
    );
  });

  testWidgets('info icon opens the other-site explanation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OtherSiteInfoButton(flavor: AppFlavor.prod)),
      ),
    );

    await tester.tap(find.byKey(const Key('other_site_info_button')));
    await tester.pumpAndSettle();

    expect(find.text('Which site is this?'), findsOneWidget);
    expect(find.textContaining('You are on the public site'), findsOneWidget);
    expect(
      find.textContaining('https://dev-belongonthespectrum.web.app/'),
      findsOneWidget,
    );
  });
}
