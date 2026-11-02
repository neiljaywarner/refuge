import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/reaction_member.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reaction_details_sheet.dart';
import 'package:refuge4serverpod/src/features/reflections/presentation/reflection_card.dart';

void main() {
  group('ReactionDetailsSheet Widget Tests', () {
    testWidgets('renders Care Affirmations sheet and lists reacting members', (tester) async {
      final now = DateTime.now();
      final post = Post(
        id: 'post_sheet_1',
        authorName: 'Santi',
        spaceKey: 'general_chat',
        toneTag: '[Relatable]',
        content: 'Loved today\'s quiet walk in the park.',
        timestamp: now,
        reactions: {'pray': 2, 'peace': 1},
        reactionMembers: {
          'pray': [
            ReactionMember(
              userId: 'u1',
              displayName: 'Neil Warner',
              timestamp: now.subtract(const Duration(minutes: 5)),
            ),
            ReactionMember(
              userId: 'u2',
              displayName: 'Carina Warner',
              timestamp: now.subtract(const Duration(minutes: 2)),
            ),
          ],
          'peace': [
            ReactionMember(
              userId: 'u3',
              displayName: 'Bruce',
              timestamp: now.subtract(const Duration(minutes: 1)),
            ),
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('open_sheet_btn'),
                onPressed: () =>
                    ReactionDetailsSheet.show(ctx, post: post, initialReactionType: 'pray'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_sheet_btn')));
      await tester.pumpAndSettle();

      // Header verified
      expect(find.text('Care Affirmations'), findsOneWidget);

      // Filter chips verified
      expect(find.byKey(const Key('reaction_chip_pray')), findsOneWidget);
      expect(find.byKey(const Key('reaction_chip_peace')), findsOneWidget);

      // Members in 'pray' tab verified
      expect(find.text('Neil Warner'), findsOneWidget);
      expect(find.text('Carina Warner'), findsOneWidget);

      // Switch to 'peace' tab
      await tester.tap(find.byKey(const Key('reaction_chip_peace')));
      await tester.pumpAndSettle();

      expect(find.text('Bruce'), findsOneWidget);
      expect(find.text('Neil Warner'), findsNothing);

      // Close button dismisses sheet
      await tester.tap(find.byKey(const Key('reaction_sheet_close_button')));
      await tester.pumpAndSettle();

      expect(find.text('Care Affirmations'), findsNothing);
    });

    testWidgets('ReflectionCard long-press opens ReactionDetailsSheet', (tester) async {
      final now = DateTime.now();
      final post = Post(
        id: 'post_card_test',
        authorName: 'Alex',
        spaceKey: 'prayer',
        toneTag: '[Support]',
        content: 'Grateful for this calm space.',
        timestamp: now,
        reactions: {'pray': 1},
        reactionMembers: {
          'pray': [ReactionMember(userId: 'u_tester', displayName: 'Jordan M.', timestamp: now)],
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReflectionCard(post: post, isContrast: false, onAddReaction: (_) {}),
            ),
          ),
        ),
      );

      // Long press on pray button
      await tester.longPress(find.byKey(const Key('reaction_button_pray_post_card_test')));
      await tester.pumpAndSettle();

      expect(find.text('Care Affirmations'), findsOneWidget);
      expect(find.text('Jordan M.'), findsOneWidget);
    });
  });
}
