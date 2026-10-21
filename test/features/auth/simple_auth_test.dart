import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/simple_auth.dart';

void main() {
  setUp(() {
    setFirebaseUiIsTestMode(true);
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        FirebaseUILocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }

  patrolWidgetTest(
    'SimpleAuthScreen mounts cleanly with official firebase_ui_auth components',
    ($) async {
      await $.pumpWidget(
        buildTestableWidget(const SimpleAuthScreen()),
      );
      await $.pump();

      // Verify SimpleAuthScreen is mounted
      expect($(SimpleAuthScreen), findsOneWidget);
    },
  );
}
