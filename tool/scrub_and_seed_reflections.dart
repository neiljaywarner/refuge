/// # Belong on the Spectrum — Reflection Scrubber & Canonical Seed CLI (`tool/scrub_and_seed_reflections.dart`)
///
/// Pure-Dart automation tool for auditing, scrubbing test junk from reflection feeds,
/// and generating/validating canonical organizer seed reflections for Belong on the Spectrum (#501, #611).
///
/// ## Usage
///
/// ```bash
/// # Audit built-in sample or provided file without modifying (Dry Run)
/// dart run tool/scrub_and_seed_reflections.dart --audit --dry-run
///
/// # Audit an external JSON export of reflections
/// dart run tool/scrub_and_seed_reflections.dart --file path/to/reflections.json --audit
///
/// # Output machine-readable JSON report for CI/verification
/// dart run tool/scrub_and_seed_reflections.dart --json --audit
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_service.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

/// Five canonical, uplifting, and authentic reflections provided by community organizers.
final List<Post> kCanonicalOrganizerReflections = [
  Post(
    id: 'canonical-organizer-welcome',
    authorName: 'Belong Organizer (DFW)',
    spaceKey: 'start_here',
    toneTag: '[Welcome]',
    specialInterestTag: 'Neurodivergent Fellowship',
    content: 'Welcome to Belong on the Spectrum! Feel free to introduce yourself here at your own pace, share a favorite hobby or special interest, or simply read quietly.',
    timestamp: DateTime.utc(2026, 10, 24, 12, 0),
    reactions: const {'pray': 9, 'peace': 14, 'encouraged': 18},
    isDemo: false,
  ),
  Post(
    id: 'canonical-general-fellowship',
    authorName: 'Hannah W. (Dallas)',
    spaceKey: 'general_chat',
    toneTag: '[Fellowship]',
    content: 'So grateful for a calm community space without flashing popups or algorithmic timelines. Wishing everyone a peaceful, restful week!',
    timestamp: DateTime.utc(2026, 10, 24, 13, 30),
    reactions: const {'pray': 6, 'peace': 12, 'encouraged': 10},
    isDemo: false,
  ),
  Post(
    id: 'canonical-study-quiet-waters',
    authorName: 'Pastor Thomas (Melbourne)',
    spaceKey: 'study',
    toneTag: '[Question]',
    content: 'In Psalm 23, David reflects on "quiet waters." How does that specific imagery ground your mental peace during hectic workdays?',
    timestamp: DateTime.utc(2026, 10, 24, 15, 0),
    reactions: const {'pray': 8, 'peace': 11, 'relatable': 7},
    isDemo: false,
  ),
  Post(
    id: 'canonical-prayer-sensory-rest',
    authorName: 'Elena R. (Colorado)',
    spaceKey: 'prayer',
    toneTag: '[Comfort Only]',
    content: 'Heavy sensory fatigue after errands today with fluorescent glare. Just needed to share in a safe room. No advice needed, just glad this quiet space exists.',
    timestamp: DateTime.utc(2026, 10, 24, 16, 45),
    reactions: const {'pray': 15, 'peace': 19},
    isDemo: false,
  ),
  Post(
    id: 'canonical-memes-church-acoustics',
    authorName: 'Nathan K. (Texas)',
    spaceKey: 'memes',
    toneTag: '[Autism & Faith Meme]',
    specialInterestTag: 'Church Acoustics',
    content: 'When the pastor says "make a joyful noise unto the Lord" and my autistic brain starts calculating the sanctuary\'s 432Hz reverberation decay. Praise God for loop earplugs in worship! 😄🎧',
    timestamp: DateTime.utc(2026, 10, 24, 17, 15),
    reactions: const {'pray': 5, 'peace': 9, 'relatable': 24},
    isDemo: false,
  ),
];

/// Result report from auditing or scrubbing a reflections collection.
class ScrubReport {
  final int totalScanned;
  final int junkCount;
  final int validCount;
  final List<String> flaggedJunkSnippets;
  final List<Post> cleanPosts;

  const ScrubReport({
    required this.totalScanned,
    required this.junkCount,
    required this.validCount,
    required this.flaggedJunkSnippets,
    required this.cleanPosts,
  });

  Map<String, dynamic> toJson() => {
    'totalScanned': totalScanned,
    'junkCount': junkCount,
    'validCount': validCount,
    'flaggedJunkSnippets': flaggedJunkSnippets,
    'cleanPostsCount': cleanPosts.length,
  };

  String toAsciiSummary() {
    final buf = StringBuffer();
    buf.writeln(
      '===============================================================',
    );
    buf.writeln(
      ' 🧹 Belong on the Spectrum — Reflection Scrubber Audit (#501, #611)',
    );
    buf.writeln(
      '===============================================================',
    );
    buf.writeln('  • Total Reflections Scanned: $totalScanned');
    buf.writeln('  • Flagged Test Junk / Clutter: $junkCount');
    buf.writeln('  • Valid Community Reflections: $validCount');
    if (flaggedJunkSnippets.isNotEmpty) {
      buf.writeln('\n--- Flagged Test Junk Samples ---');
      for (final snippet in flaggedJunkSnippets.take(10)) {
        buf.writeln('  ⚠️  $snippet');
      }
    }
    buf.writeln(
      '===============================================================',
    );
    return buf.toString();
  }
}

/// Core domain scrubber service for reflections data.
class ReflectionScrubber {
  const ReflectionScrubber();

  /// Audits a list of [posts] and separates valid reflections from developer test junk.
  ScrubReport audit(List<Post> posts) {
    final junkSnippets = <String>[];
    final clean = <Post>[];

    for (final post in posts) {
      if (FeedQuery.isTestJunk(post)) {
        final preview = post.content.length > 50
            ? '${post.content.substring(0, 50)}...'
            : post.content;
        junkSnippets.add('[Author: ${post.authorName}] "$preview"');
      } else {
        clean.add(post);
      }
    }

    return ScrubReport(
      totalScanned: posts.length,
      junkCount: junkSnippets.length,
      validCount: clean.length,
      flaggedJunkSnippets: junkSnippets,
      cleanPosts: clean,
    );
  }

  /// Parses JSON records into [Post] objects.
  List<Post> parseJsonPosts(List<dynamic> jsonList) {
    final list = <Post>[];
    for (final raw in jsonList) {
      if (raw is Map<String, dynamic>) {
        try {
          list.add(
            Post(
              id: raw['id']?.toString() ?? 'unknown',
              authorName: raw['authorName']?.toString() ?? 'Anonymous',
              spaceKey: raw['spaceKey']?.toString() ?? 'general_chat',
              toneTag:
                  raw['toneTag']?.toString() ??
                  raw['intentTag']?.toString() ??
                  '[Support]',
              specialInterestTag: raw['specialInterestTag']?.toString(),
              imageUrl: raw['imageUrl']?.toString(),
              content: raw['content']?.toString() ?? '',
              timestamp:
                  DateTime.tryParse(
                    raw['timestamp']?.toString() ??
                        raw['createdAt']?.toString() ??
                        '',
                  ) ??
                  DateTime.now(),
              reactions: (raw['reactions'] is Map)
                  ? (raw['reactions'] as Map).map(
                      (k, v) => MapEntry(k.toString(), (v as num).toInt()),
                    )
                  : const {},
              isDemo: raw['isDemo'] == true,
            ),
          );
        } catch (_) {}
      }
    }
    return list;
  }
}

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }

  final isJson = args.contains('--json');
  String? filePath;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--file' && i + 1 < args.length) {
      filePath = args[i + 1];
      break;
    }
  }

  final scrubber = const ReflectionScrubber();
  List<Post> postsToAudit = [];

  if (filePath != null) {
    final file = File(filePath);
    if (!await file.exists()) {
      stderr.writeln('❌ Error: Input file not found: $filePath');
      exit(66); // EX_NOINPUT
    }
    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        postsToAudit = scrubber.parseJsonPosts(decoded);
      } else if (decoded is Map<String, dynamic> &&
          decoded['reflections'] is List) {
        postsToAudit = scrubber.parseJsonPosts(decoded['reflections'] as List);
      } else {
        stderr.writeln(
          '❌ Error: JSON file must contain a list of reflection objects.',
        );
        exit(65); // EX_DATAERR
      }
    } catch (e) {
      stderr.writeln('❌ Error parsing JSON file: $e');
      exit(65);
    }
  } else {
    // Audit sample dataset containing both canonical posts and sample test junk
    postsToAudit = [
      ...kCanonicalOrganizerReflections,
      Post(
        id: 'junk-1',
        authorName: 'Random Tester',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'blah your face this is a test',
        timestamp: DateTime.now(),
        reactions: const {},
      ),
      Post(
        id: 'junk-2',
        authorName: 'grokbot1',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'Quiet hello grokbot-mention-token @grokbot2',
        timestamp: DateTime.now(),
        reactions: const {},
      ),
      Post(
        id: 'junk-3',
        authorName: 'Tester',
        spaceKey: 'prayer',
        toneTag: '[Comfort Only]',
        content: 'test 1 check microphone',
        timestamp: DateTime.now(),
        reactions: const {},
      ),
      Post(
        id: 'junk-4',
        authorName: 'Developer',
        spaceKey: 'general_chat',
        toneTag: '[Question]',
        content: 'quick test for dev backend',
        timestamp: DateTime.now(),
        reactions: const {},
      ),
      Post(
        id: 'junk-5',
        authorName: 'Tester',
        spaceKey: 'general_chat',
        toneTag: '[Question]',
        content: 'asdf asdf asdf',
        timestamp: DateTime.now(),
        reactions: const {},
      ),
    ];
  }

  final report = scrubber.audit(postsToAudit);

  if (isJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  } else {
    stdout.writeln(report.toAsciiSummary());
  }

  exit(0);
}

void _printUsage() {
  stdout.writeln('''
===============================================================
 🧹 Belong on the Spectrum — Reflection Scrubber CLI (#501, #611)
===============================================================

Usage:
  dart run tool/scrub_and_seed_reflections.dart [options]

Options:
  --audit          Audit reflections and report test clutter statistics
  --dry-run        Audit without saving output (default)
  --file <path>    Path to a JSON file containing reflections
  --json           Output results as machine-readable JSON
  -h, --help       Show this help message
''');
}
