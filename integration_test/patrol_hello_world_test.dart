import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolWidgetTest(
    'Firebase Test Lab Hello World: Boots Belong App, checks top bar and bottom nav',
    ($) async {
      await $.pumpWidgetAndSettle(
        SanctuaryApp(
          repository: LocalPostRepository(),
        ),
      );

      // 1. Verify community app title and branding
      expect($('Belong'), findsOneWidget);
      expect($('Sanctuary'), findsOneWidget);

      // 2. Verify bottom navigation tabs are present
      expect($('Home'), findsOneWidget);
      expect($('Spaces'), findsOneWidget);
      expect($('Msgs'), findsOneWidget);
      expect($('Notifications'), findsOneWidget);

      // 3. Verify intent filter row
      expect($('Filter: '), findsOneWidget);
      expect($(ChoiceChip), findsWidgets);
      expect($('[Prayer Request]'), findsWidgets);

      // 4. Tap the first ChoiceChip and settle
      await $(ChoiceChip).first.tap();
      await $.pumpAndSettle();
    },
  );
}
