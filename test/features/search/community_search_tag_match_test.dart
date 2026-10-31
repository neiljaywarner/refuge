import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';
import 'package:refuge4serverpod/src/features/search/presentation/community_search_match.dart';

void main() {
  group('communitySearchMatchedTagLabel', () {
    final post = Post(
      id: '1',
      authorName: 'David M. (UK)',
      spaceKey: 'prayer',
      toneTag: '[Prayer Request]',
      content: 'Please pray for peace of mind this week.',
      timestamp: DateTime.utc(2026, 10, 1),
      reactions: const {},
    );

    test('returns null when query is empty', () {
      expect(communitySearchMatchedTagLabel(post: post, query: ''), isNull);
    });

    test('returns null when body text matches query', () {
      expect(communitySearchMatchedTagLabel(post: post, query: 'peace'), isNull);
    });

    test('returns tone tag label when only intent tag matches', () {
      expect(
        communitySearchMatchedTagLabel(post: post, query: 'prayer'),
        equals('Matched tag: Prayer Request'),
      );
    });

    test('returns special interest label when only tag field matches', () {
      final meme = post.copyWith(
        toneTag: '[Resource]',
        specialInterestTag: 'Christian Memes',
        content: 'Link to a calm video guide.',
      );
      expect(
        communitySearchMatchedTagLabel(post: meme, query: 'memes'),
        equals('Matched tag: Christian Memes'),
      );
    });
  });
}
