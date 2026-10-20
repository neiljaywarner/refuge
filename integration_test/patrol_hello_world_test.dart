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
      expect($('Belong on the Spectrum'), findsOneWidget);

      // 2. Verify bottom navigation tabs are present
      expect($('Home'), findsOneWidget);
      expect($('Spaces'), findsOneWidget);
      expect($('Msgs'), findsOneWidget);
      expect($('Events'), findsOneWidget);

      // 3. Verify emotional tone filter chips
      expect($('🌱 Gentle'), findsOneWidget);
      expect($('🎯 Clarity'), findsOneWidget);
      expect($('🎉 Joy'), findsOneWidget);
      expect($('🤝 Help'), findsOneWidget);

      // 4. Tap the Gentle tone filter chip and settle
      await $(find.text('🌱 Gentle')).tap();
      await $.pumpAndSettle();
    },
  );
}
