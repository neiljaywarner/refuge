import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/src/features/auth/presentation/simple_auth.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockFirebaseApp extends Mock implements FirebaseApp {}

void main() {
  late _MockFirebaseAuth mockAuth;
  late _MockFirebaseApp mockApp;

  setUpAll(() {
    setFirebaseUiIsTestMode(true);
  });

  setUp(() {
    mockAuth = _MockFirebaseAuth();
    mockApp = _MockFirebaseApp();
    when(() => mockAuth.authStateChanges()).thenAnswer(
      (_) => Stream<User?>.value(null),
    );
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockAuth.app).thenReturn(mockApp);
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          FirebaseUILocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );
  }

  patrolWidgetTest(
    'SimpleAuthScreen mounts cleanly with official firebase_ui_auth components',
    ($) async {
      await $.pumpWidget(
        buildTestableWidget(const SimpleAuthScreen()),
      );
      await $.pump();

      expect($(SimpleAuthScreen), findsOneWidget);
    },
  );

  patrolWidgetTest(
    'SimpleAuthScreen shows password visibility toggle on Firebase UI sign-in (#593)',
    ($) async {
      await $.pumpWidget(
        buildTestableWidget(SimpleAuthScreen(auth: mockAuth)),
      );
      await $.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    },
  );

  patrolWidgetTest(
    'SimpleAuthScreen password visibility toggle switches eye icon (#593)',
    ($) async {
      await $.pumpWidget(
        buildTestableWidget(SimpleAuthScreen(auth: mockAuth)),
      );
      await $.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await $(find.byIcon(Icons.visibility)).tap();
      await $.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    },
  );
}
