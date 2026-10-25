import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/core/theme/belong_text_styles.dart';

void main() {
  testWidgets('contrast theme title is yellow and caption stays quiet', (tester) async {
    final contrast = BelongTextStyles.forTheme(ThemeData.dark(), contrast: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(extensions: [contrast]),
        home: Builder(
          builder: (context) {
            final styles = BelongTextStyles.of(context);
            return Column(
              children: [
                Text('Title', style: styles.title),
                Text('Body', style: styles.body),
                Text('Caption', style: styles.caption),
                Text('Emphasis', style: styles.emphasis),
              ],
            );
          },
        ),
      ),
    );

    TextStyle styleOf(String text) => tester.widget<Text>(find.text(text)).style!;

    expect(styleOf('Title').color, const Color(0xFFFFEB3B));
    expect(styleOf('Title').fontWeight, FontWeight.bold);
    expect(styleOf('Body').color, Colors.white);
    expect(styleOf('Caption').fontSize, 11.5);
    expect(styleOf('Emphasis').fontWeight, FontWeight.bold);
  });

  testWidgets('missing extension falls back to the ambient theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Text('Hello', style: BelongTextStyles.of(context).body),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Hello')).style?.fontSize, 14);
  });
}
