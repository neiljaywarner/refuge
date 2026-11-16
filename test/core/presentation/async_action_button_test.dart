import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/presentation/async_action_button.dart';

Widget _host(Widget child, {double textScale = 1.0}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: Center(child: child)),
  ),
);

const _key = Key('async_button');

void main() {
  for (final variant in AsyncButtonVariant.values) {
    group('AsyncActionButton.$variant', () {
      late int calls;
      late Completer<void> gate;

      Future<void> work() {
        calls++;
        return gate.future;
      }

      // Completers are created inside each test body so they complete in the
      // test's fake-async zone (a setUp-created one would never settle).
      setUp(() => calls = 0);

      Widget button() => AsyncActionButton(
        key: _key,
        variant: variant,
        onPressed: work,
        icon: const Icon(Icons.send),
        busyLabel: 'Sending',
        child: const Text('Send'),
      );

      testWidgets('a double tap runs the action once and shows a spinner', (tester) async {
        gate = Completer<void>();
        await tester.pumpWidget(_host(button()));
        final sizeBefore = tester.getSize(find.byKey(_key));

        await tester.tap(find.byKey(_key));
        await tester.tap(find.byKey(_key), warnIfMissed: false);
        await tester.pump();

        expect(calls, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.bySemanticsLabel('Sending'), findsOneWidget);
        expect(tester.getSize(find.byKey(_key)), sizeBefore, reason: 'no layout jump');

        await tester.tap(find.byKey(_key), warnIfMissed: false);
        await tester.pump();
        expect(calls, 1);

        gate.complete();
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('re-enables after the action completes', (tester) async {
        gate = Completer<void>();
        await tester.pumpWidget(_host(button()));
        await tester.tap(find.byKey(_key));
        await tester.pump();
        gate.complete();
        await tester.pumpAndSettle();

        gate = Completer<void>()..complete();
        await tester.tap(find.byKey(_key));
        await tester.pumpAndSettle();
        expect(calls, 2);
      });

      testWidgets('re-enables after the action throws and reports the error', (tester) async {
        gate = Completer<void>();
        await tester.pumpWidget(_host(button()));
        await tester.tap(find.byKey(_key));
        await tester.pump();
        gate.completeError(StateError('network down'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isA<StateError>());
        expect(find.byType(CircularProgressIndicator), findsNothing);

        gate = Completer<void>()..complete();
        await tester.tap(find.byKey(_key));
        await tester.pumpAndSettle();
        expect(calls, 2);
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(
          _host(
            AsyncActionButton(
              key: _key,
              variant: variant,
              onPressed: null,
              icon: const Icon(Icons.send),
              child: const Text('Send'),
            ),
          ),
        );
        await tester.tap(find.byKey(_key), warnIfMissed: false);
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
  }

  testWidgets('spinner grows with large text', (tester) async {
    final gate = Completer<void>();
    Future<void> work() => gate.future;
    Future<double> spinnerSize(double scale) async {
      await tester.pumpWidget(
        _host(
          AsyncActionButton(key: UniqueKey(), onPressed: work, child: const Text('Save')),
          textScale: scale,
        ),
      );
      await tester.tap(find.byType(AsyncActionButton));
      await tester.pump();
      return tester.getSize(find.byType(CircularProgressIndicator)).height;
    }

    final normal = await spinnerSize(1.0);
    final large = await spinnerSize(2.0);
    expect(large, greaterThan(normal));
    gate.complete();
    await tester.pumpAndSettle();
  });
}
