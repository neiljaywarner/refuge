import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/text_scale.dart';
import 'large_text_surfaces.dart';

void main() {
  testWidgets('direct messages list and thread stay usable at large text scales', (tester) async {
    for (final scale in largeTextScales) {
      final session = await pumpMessagesAtScale(tester, scale);
      expect(find.text('Direct Messages'), findsOneWidget);
      expect(find.text('Marty & Community Team'), findsWidgets);
      expectMinTapTarget(tester, find.byKey(const Key('add_new_message_button')));
      await openFirstMessageThread(tester, session);
      expect(find.text('Marty & Community Team'), findsWidgets);
      expectMinTapTarget(tester, find.byKey(const Key('back-to-messages-list')));
    }
  });
}
