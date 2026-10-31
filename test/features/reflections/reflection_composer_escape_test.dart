import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_composer.dart';

void main() {
  testWidgets('Escape dismisses modal reflection composer when body field is focused', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) => ReflectionComposer(
                      selectedSpace: 'prayer',
                      primaryColor: Colors.green,
                      isContrast: false,
                      isModal: true,
                      onSubmit: ({
                        required content,
                        required toneTag,
                        specialInterestTag,
                        imageUrl,
                      }) async {},
                    ),
                  );
                },
                child: const Text('Open composer'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open composer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reflection_composer_input')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reflection_composer_input')));
    await tester.enterText(find.byKey(const Key('reflection_composer_input')), 'Draft thought');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reflection_composer_input')), findsNothing);
  });
}
