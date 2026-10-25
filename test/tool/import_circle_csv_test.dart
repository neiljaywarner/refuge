import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/src/tool/circle_csv_importer.dart';

void main() {
  group('CircleSpaceMapper Tests (#41)', () {
    test('resolves canonical Belong space slugs from Circle space names', () {
      expect(
        CircleSpaceMapper.resolveSpaceSlug('Start Here & Introduce Yourself'),
        equals('start_here'),
      );
      expect(
        CircleSpaceMapper.resolveSpaceSlug('Start Here'),
        equals('start_here'),
      );
      expect(
        CircleSpaceMapper.resolveSpaceSlug('Announcements'),
        equals('announcements'),
      );
      expect(
        CircleSpaceMapper.resolveSpaceSlug('General Chat'),
        equals('general_chat'),
      );
      expect(
        CircleSpaceMapper.resolveSpaceSlug('general'),
        equals('general_chat'),
      );
      expect(CircleSpaceMapper.resolveSpaceSlug('Memes'), equals('memes'));
      expect(
        CircleSpaceMapper.resolveSpaceSlug('Online Resources / Videos'),
        equals('resources_videos'),
      );
      expect(
        CircleSpaceMapper.resolveSpaceSlug('Actually Autistic Chat'),
        equals('actually_autistic_chat'),
      );
      expect(
        CircleSpaceMapper.resolveSpaceSlug('Friends Chat'),
        equals('friends_chat'),
      );
      expect(
        CircleSpaceMapper.resolveSpaceSlug('Family Chat'),
        equals('family_chat'),
      );
    });

    test('returns unmapped_space for unrecognized space names', () {
      expect(
        CircleSpaceMapper.resolveSpaceSlug('Random Offtopic Club'),
        equals('unmapped_space'),
      );
      expect(CircleSpaceMapper.resolveSpaceSlug(''), equals('unmapped_space'));
    });

    test('supports custom space overrides', () {
      final overrides = {'random offtopic club': 'general_chat'};
      expect(
        CircleSpaceMapper.resolveSpaceSlug(
          'Random Offtopic Club',
          customOverrides: overrides,
        ),
        equals('general_chat'),
      );
    });

    test(
      'provides valid sections and display names for all canonical spaces',
      () {
        const canonicalSlugs = [
          'start_here',
          'announcements',
          'general_chat',
          'memes',
          'resources_videos',
          'actually_autistic_chat',
          'friends_chat',
          'family_chat',
        ];

        for (final slug in canonicalSlugs) {
          expect(CircleSpaceMapper.spaceSections.containsKey(slug), isTrue);
          expect(CircleSpaceMapper.spaceDisplayNames.containsKey(slug), isTrue);
        }
      },
    );
  });

  group('CircleCsvParser Tests (#41)', () {
    test('parses simple comma-separated records', () {
      const csv = '''
space,title,body,author_name,author_email,created_at
"General Chat","Hello","Just testing simple parsing","Alex","alex@example.com","2026-09-01T10:00:00Z"
''';
      final records = CircleCsvParser.parseRecords(csv);
      expect(records.length, equals(1));
      expect(records.first.belongSpaceSlug, equals('general_chat'));
      expect(records.first.title, equals('Hello'));
      expect(records.first.body, equals('Just testing simple parsing'));
      expect(records.first.authorName, equals('Alex'));
      expect(records.first.isValid, isTrue);
    });

    test('handles quotes, commas inside quotes, and escaped quotes ("")', () {
      const csv = '''
space,title,body,author_name,author_email,created_at
"Memes","Title with, commas","Body has ""double quotes"" and, commas, too!","Jordan","jordan@example.com","2026-09-02T12:00:00Z"
''';
      final records = CircleCsvParser.parseRecords(csv);
      expect(records.length, equals(1));
      final record = records.first;
      expect(record.title, equals('Title with, commas'));
      expect(record.body, equals('Body has "double quotes" and, commas, too!'));
      expect(record.belongSpaceSlug, equals('memes'));
    });

    test('handles multiline fields across line breaks', () {
      const csv = '''
space,title,body,author_name,author_email,created_at
"General Chat","Multiline Post","Paragraph 1

Paragraph 2 with thoughts","Hannah","hannah@example.com","2026-09-03T15:00:00Z"
''';
      final records = CircleCsvParser.parseRecords(csv);
      expect(records.length, equals(1));
      expect(records.first.body, contains('Paragraph 1\n\nParagraph 2'));
    });

    test('parses Circle YYYY-MM-DD HH:MM:SS UTC date timestamps correctly', () {
      const csv = '''
space,title,body,author_name,author_email,created_at
"Announcements","Meeting","Agenda here","Marty","marty@example.com","2026-08-20 09:00:00 UTC"
''';
      final records = CircleCsvParser.parseRecords(csv);
      expect(records.length, equals(1));
      final date = records.first.createdAt;
      expect(date.year, equals(2026));
      expect(date.month, equals(8));
      expect(date.day, equals(20));
      expect(date.hour, equals(9));
    });
  });

  group('CircleCsvImporter In-Memory Analysis (#41)', () {
    test('generates accurate audit report and ASCII table', () {
      const csv = '''
space,title,body,author_name,author_email,created_at
"Start Here","Welcome","Hi!","Hannah","hannah@example.com","2026-08-01 10:00:00 UTC"
"General Chat","Topic 1","Discussion 1","Alex","alex@example.com","2026-08-05 12:00:00 UTC"
"General Chat","Topic 2","Discussion 2","Sam","sam@example.com","2026-08-10 14:00:00 UTC"
"Unknown Space","Skip me","Nothing here","Guest","guest@example.com","2026-08-11 16:00:00 UTC"
''';
      const importer = CircleCsvImporter();
      final report = importer.analyzeContent(csv, filePath: 'test.csv');

      expect(report.totalRowsRead, equals(4));
      expect(report.validRecordsCount, equals(3));
      expect(report.unmappedSpaceCount, equals(1));
      expect(report.recordsPerSpace['start_here'], equals(1));
      expect(report.recordsPerSpace['general_chat'], equals(2));
      expect(report.uniqueAuthorsCount, equals(4));

      final ascii = report.toAsciiTable();
      expect(ascii, contains('Circle.so CSV Migration Report (DRY RUN)'));
      expect(ascii, contains('start_here'));
      expect(ascii, contains('general_chat'));
      expect(ascii, contains('Total Rows Read:    4'));
    });

    test('anonymizes authorEmail in toJson representation (Zero-PII)', () {
      final record = CircleRecord(
        originalSpaceName: 'General Chat',
        belongSpaceSlug: 'general_chat',
        title: 'Title',
        body: 'Body',
        authorName: 'Alex',
        authorEmail: 'secret@domain.com',
        createdAt: DateTime.fromMicrosecondsSinceEpoch(0),
      );

      final json = record.toJson();
      expect(json['authorEmail'], equals('[ANONYMIZED_PII]'));
      expect(json['authorEmail'], isNot(contains('secret@domain.com')));
    });
  });

  group('Sample Anonymized Circle Export Fixture Tests (#41)', () {
    test('sample fixture exists and parses 10 valid records with zero unmapped spaces', () async {
      const fixturePath = 'test/fixtures/sample_anonymized_circle_export.csv';
      final file = File(fixturePath);
      expect(await file.exists(), isTrue, reason: 'Fixture must exist');

      const importer = CircleCsvImporter();
      final report = await importer.analyzeFile(fixturePath, isDryRun: true);

      expect(report.totalRowsRead, equals(10));
      expect(report.validRecordsCount, equals(10));
      expect(report.unmappedSpaceCount, equals(0));

      // Check space coverage
      expect(report.recordsPerSpace['start_here'], equals(2));
      expect(report.recordsPerSpace['announcements'], equals(1));
      expect(report.recordsPerSpace['general_chat'], equals(2));
      expect(report.recordsPerSpace['memes'], equals(1));
      expect(report.recordsPerSpace['resources_videos'], equals(1));
      expect(report.recordsPerSpace['actually_autistic_chat'], equals(1));
      expect(report.recordsPerSpace['friends_chat'], equals(1));
      expect(report.recordsPerSpace['family_chat'], equals(1));

      // Check author count
      expect(report.uniqueAuthorsCount, equals(6));

      // Strict Zero-PII check: ensure no real emails leaked in fixture
      final content = await file.readAsString();
      expect(content, isNot(contains('gmail.com')));
      expect(content, isNot(contains('yahoo.com')));
      expect(content, isNot(contains('circle.so')));
    });
  });
}
