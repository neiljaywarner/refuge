import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'patrol_app_harness.dart';

/// LeanCode Patrol native automation: background the app and resume (read-only).
///
/// See https://patrol.leancode.co/documentation/native/overview
void main() {
  patrolTest(
    'FTL: press Home and reopen dev app without losing home shell',
    ($) async {
      await pumpDevReadOnlyHome($);
      expect($('Vote & Feedback'), findsOneWidget);

      if (Platform.isAndroid || Platform.isIOS) {
        await $.platform.mobile.pressHome();
        await $.platform.mobile.openApp(
          appId: 'com.belongonthespectrum.refuge.dev',
        );
        await $.pumpAndSettle();
        expect($('Vote & Feedback'), findsOneWidget);
      }
    },
  );
}
