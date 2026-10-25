import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolWidgetTest(
    'Firebase Test Lab Hello World: read-only home shell and bottom nav',
    ($) async {
      await $.pumpWidgetAndSettle(
        RefugeApp(
          repository: LocalPostRepository(),
        ),
      );

      expect($('Belong'), findsOneWidget);
      expect($('Refuge'), findsOneWidget);

      expect($('Home'), findsOneWidget);
      expect($('Notifications'), findsOneWidget);
      expect($('Messages'), findsOneWidget);
      expect($('Search'), findsOneWidget);

      expect($('Filter: '), findsOneWidget);
      expect($(ChoiceChip), findsWidgets);
      expect($('[Prayer Request]'), findsWidgets);

      expect($('Vote & Feedback'), findsOneWidget);
    },
  );
}
