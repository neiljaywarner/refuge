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

import 'package:refuge4serverpod/src/features/reflections/data/canonical_organizer_starter_posts.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/feed_sort_service.dart';
import 'package:refuge4serverpod/src/features/reflections/domain/post.dart';

export 'package:refuge4serverpod/src/features/reflections/data/canonical_organizer_starter_posts.dart';

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
    buf.writeln('===============================================================');
    buf.writeln(' 🧹 Belong on the Spectrum — Reflection Scrubber Audit (#501, #611)');
    buf.writeln('===============================================================');
    buf.writeln('  • Total Reflections Scanned: $totalScanned');
    buf.writeln('  • Flagged Test Junk / Clutter: $junkCount');
    buf.writeln('  • Valid Community Reflections: $validCount');
    if (flaggedJunkSnippets.isNotEmpty) {
      buf.writeln('\n--- Flagged Test Junk Samples ---');
      for (final snippet in flaggedJunkSnippets.take(10)) {
        buf.writeln('  ⚠️  $snippet');
      }
    }
    buf.writeln('===============================================================');
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
              toneTag: raw['toneTag']?.toString() ?? raw['intentTag']?.toString() ?? '[Support]',
              specialInterestTag: raw['specialInterestTag']?.toString(),
              imageUrl: raw['imageUrl']?.toString(),
              content: raw['content']?.toString() ?? '',
              timestamp:
                  DateTime.tryParse(
                    raw['timestamp']?.toString() ?? raw['createdAt']?.toString() ?? '',
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

  String? exportSeedPath;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--export-seed' && i + 1 < args.length) {
      exportSeedPath = args[i + 1];
      break;
    }
  }

  if (exportSeedPath != null) {
    final file = File(exportSeedPath);
    final payload = kCanonicalOrganizerReflections.map(_postToExportJson).toList();
    await file.writeAsString('${const JsonEncoder.withIndent('  ').convert(payload)}\n');
    stdout.writeln('Exported ${payload.length} canonical reflections to $exportSeedPath');
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
      } else if (decoded is Map<String, dynamic> && decoded['reflections'] is List) {
        postsToAudit = scrubber.parseJsonPosts(decoded['reflections'] as List);
      } else {
        stderr.writeln('❌ Error: JSON file must contain a list of reflection objects.');
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
  --export-seed <path>  Write kCanonicalOrganizerReflections JSON to path (#664)
  --json           Output results as machine-readable JSON
  -h, --help       Show this help message
''');
}

Map<String, dynamic> _postToExportJson(Post post) => {
  'id': post.id,
  'authorName': post.authorName,
  'spaceKey': post.spaceKey,
  'toneTag': post.toneTag,
  if (post.specialInterestTag != null) 'specialInterestTag': post.specialInterestTag,
  if (post.imageUrl != null) 'imageUrl': post.imageUrl,
  'content': post.content,
  'timestamp': post.timestamp.toUtc().toIso8601String(),
  'reactions': post.reactions,
  'isDemo': post.isDemo,
};
