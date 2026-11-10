import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/text_scale.dart';
import 'large_text_surfaces.dart';

void main() {
  testWidgets('a reflection card does not overflow at large text scales', (tester) async {
    for (final scale in largeTextScales) {
      final session = await pumpPostCardAtScale(tester, scale);
      expect(find.byKey(const Key('author_tap_target_1')), findsOneWidget);
      final save = find.byKey(const Key('save_post_button_1'));
      await tester.ensureVisible(save);
      await tester.pump();
      session.check();
      expectMinTapTarget(tester, save);
      final discussion = find.byKey(const Key('discussion_button_1'));
      await tester.ensureVisible(discussion);
      await tester.pump();
      session.check();
      expectMinTapTarget(tester, discussion);
    }
  });

  testWidgets('post discussion stays usable at large text scales', (tester) async {
    for (final scale in largeTextScales) {
      await pumpPostDetailAtScale(tester, scale);
      expect(find.byKey(const Key('threaded_discussion_sheet_title')), findsOneWidget);
      expect(find.text('Discussion & Replies'), findsOneWidget);
      expectMinTapTarget(tester, find.byKey(const Key('close_discussion_sheet_button')));
    }
  });
}
