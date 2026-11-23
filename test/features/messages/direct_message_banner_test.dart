import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/messages/presentation/direct_message_arrival_banner.dart';

void main() {
  testWidgets('the same open-app message is shown once and can be dismissed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: const Scaffold(body: Text('Home')),
      ),
    );

    showDirectMessageBanner('   ');
    showDirectMessageBanner('  A quiet note.  ');
    showDirectMessageBanner('A quiet note.');
    await tester.pump();

    expect(find.text('A quiet note.'), findsOneWidget);
    expect(find.byIcon(Icons.message_outlined), findsOneWidget);
    rootScaffoldMessengerKey.currentState!.hideCurrentMaterialBanner();
    await tester.pumpAndSettle();
    expect(find.text('A quiet note.'), findsNothing);

    showDirectMessageBanner('A second note.');
    await tester.pump();
    expect(find.text('A second note.'), findsOneWidget);
  });

  testWidgets('a banner without a messenger is not remembered as shown', (tester) async {
    showDirectMessageBanner('No messenger yet.');
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    showDirectMessageBanner('No messenger yet.');
    await tester.pump();
    expect(find.text('No messenger yet.'), findsOneWidget);
  });
}
