import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

import '../../tool/scrub_and_seed_reflections.dart';

void main() {
  group('ReflectionScrubber Unit & Domain Tests (#501, #611)', () {
    const scrubber = ReflectionScrubber();

    test('audit separates clean posts from developer test junk', () {
      final samplePosts = [
        ...kCanonicalOrganizerReflections,
        Post(
          id: 'test-junk-1',
          authorName: 'Debug User',
          spaceKey: 'general_chat',
          toneTag: '[Question]',
          content: 'blah your face',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
        Post(
          id: 'test-junk-2',
          authorName: 'grokbot',
          spaceKey: 'prayer',
          toneTag: '[Prayer Request]',
          content: 'valid content but author is a bot',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
        Post(
          id: 'test-junk-3',
          authorName: 'Tester',
          spaceKey: 'general_chat',
          toneTag: '[Question]',
          content: 'test 42 probe',
          timestamp: DateTime.now(),
          reactions: const {},
        ),
      ];

      final report = scrubber.audit(samplePosts);

      expect(report.totalScanned, samplePosts.length);
      expect(report.junkCount, 3);
      expect(report.validCount, kCanonicalOrganizerReflections.length);
      expect(report.cleanPosts.length, kCanonicalOrganizerReflections.length);
      expect(report.flaggedJunkSnippets.length, 3);

      final jsonReport = report.toJson();
      expect(jsonReport['totalScanned'], samplePosts.length);
      expect(jsonReport['junkCount'], 3);
      expect(jsonReport['validCount'], kCanonicalOrganizerReflections.length);

      final ascii = report.toAsciiSummary();
      expect(ascii, contains('Reflection Scrubber Audit'));
      expect(ascii, contains('Flagged Test Junk / Clutter: 3'));
    });

    test('canonical organizer reflections are 100% valid with zero junk', () {
      final report = scrubber.audit(kCanonicalOrganizerReflections);
      expect(report.junkCount, 0);
      expect(report.validCount, kCanonicalOrganizerReflections.length);

      // Verify each canonical reflection has authentic metadata
      for (final post in kCanonicalOrganizerReflections) {
        expect(post.content.isNotEmpty, isTrue);
        expect(post.authorName.isNotEmpty, isTrue);
        expect(post.spaceKey.isNotEmpty, isTrue);
        expect(post.toneTag.startsWith('['), isTrue);
        expect(post.toneTag.endsWith(']'), isTrue);
      }
    });

    test(
      'parseJsonPosts correctly parses JSON records and handles edge cases',
      () {
        final jsonList = [
          {
            'id': 'json-1',
            'authorName': 'Sarah',
            'spaceKey': 'prayer',
            'toneTag': '[Prayer Request]',
            'content': 'Peace be with you all.',
            'timestamp': '2026-10-24T12:00:00Z',
            'reactions': {'pray': 5},
            'isDemo': false,
          },
          {'id': 'json-2', 'authorName': 'Tester', 'content': 'quick test'},
          'invalid non-map entry',
        ];

        final parsed = scrubber.parseJsonPosts(jsonList);
        expect(parsed.length, 2);
        expect(parsed[0].id, 'json-1');
        expect(parsed[0].authorName, 'Sarah');
        expect(parsed[0].reactions['pray'], 5);
        expect(parsed[1].id, 'json-2');
        expect(parsed[1].spaceKey, 'general_chat'); // default fallback
      },
    );
  });
}
