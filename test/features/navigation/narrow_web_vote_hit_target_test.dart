import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('Narrow Web Vote ≠ Create Post Hit Target Isolation (#619)', () {
    testWidgets(
      'Vote & Feedback and Create Post have isolated non-overlapping bounds on 360px viewport',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
            return;
          }
          previousOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousOnError);

        await tester.pumpWidget(RefugeApp(repository: LocalPostRepository()));
        await tester.pumpAndSettle();

        final createPostFinder = find.byKey(const Key('home_top_bar_create_post_button'));
        final voteChipFinder = find.byKey(const Key('open_feedback_and_voting_button'));

        expect(createPostFinder, findsOneWidget);
        expect(voteChipFinder, findsOneWidget);

        final createRect = tester.getRect(createPostFinder);
        final voteRect = tester.getRect(voteChipFinder);

        // Verify no bounding box overlap: Vote & Feedback must strictly sit below the top app bar
        expect(voteRect.top, greaterThanOrEqualTo(createRect.bottom));
        expect(voteRect.height, greaterThanOrEqualTo(32.0));

        // 5/5 consecutive taps on Vote & Feedback must open the voting sheet, never Create Post
        for (int i = 0; i < 5; i++) {
          await tester.tap(voteChipFinder);
          await tester.pumpAndSettle();

          // Must display Belong Roadmap & Feedback modal
          expect(find.text('Belong Roadmap & Feedback'), findsOneWidget);
          // Must NEVER have triggered Create Post popup menu
          expect(find.byKey(const Key('menu_item_create_post')), findsNothing);

          // Dismiss the sheet
          await tester.tap(find.byKey(const Key('close_feedback_sheet_button')));
          await tester.pumpAndSettle();
        }

        // Create Post button remains reachable and triggers its own menu
        await tester.tap(createPostFinder);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('menu_item_create_post')), findsOneWidget);
        expect(find.byKey(const Key('menu_item_create_image_post')), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping near the top border of Vote & Feedback does not trigger Create Post on 390px viewport',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
            return;
          }
          previousOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousOnError);

        await tester.pumpWidget(RefugeApp(repository: LocalPostRepository()));
        await tester.pumpAndSettle();

        final voteChipFinder = find.byKey(const Key('open_feedback_and_voting_button'));
        expect(voteChipFinder, findsOneWidget);

        final voteRect = tester.getRect(voteChipFinder);
        // Tap precisely at the top-left edge of the Vote chip
        await tester.tapAt(Offset(voteRect.left + 5, voteRect.top + 2));
        await tester.pumpAndSettle();

        expect(find.text('Belong Roadmap & Feedback'), findsOneWidget);
        expect(find.byKey(const Key('menu_item_create_post')), findsNothing);
      },
    );
  });
}
