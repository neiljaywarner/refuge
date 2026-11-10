import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'text_scale.dart';

void main() {
  test('large text scales cover 1.0, 1.3, 2.0, and 3.0', () {
    expect(largeTextScales, [1.0, 1.3, 2.0, 3.0]);
  });

  testWidgets('pumpWithTextScale applies the scaler and allows wrapping text', (tester) async {
    final session = await pumpWithTextScale(
      tester,
      const Scaffold(body: Text('Hello', key: Key('hello'))),
      scale: 2,
    );

    final context = tester.element(find.byKey(const Key('hello')));
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(20, 0.01));
    session.check();
  });

  testWidgets('pumpWithTextScale fails when a row overflows', (tester) async {
    Object? error;
    try {
      await pumpWithTextScale(
        tester,
        const Scaffold(
          body: SizedBox(width: 30, child: Row(children: [Text('this line is far too wide')])),
        ),
        scale: 2,
      );
    } catch (caught) {
      error = caught;
    }
    expect(error, isA<TestFailure>());
    expect('$error', contains('overflowed'));
  });

  testWidgets('a control under 48dp fails the tap-target check', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 20, height: 20, child: Text('x', key: Key('tiny'))),
        ),
      ),
    );

    expect(
      () => expectMinTapTarget(tester, find.byKey(const Key('tiny'))),
      throwsA(isA<TestFailure>()),
    );
  });
}
