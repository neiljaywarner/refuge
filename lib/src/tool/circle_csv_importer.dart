import 'dart:convert';
import 'dart:io';

/// Canonical mappings from Circle.so Space names to Belong Space slugs (#41).
class CircleSpaceMapper {
  const CircleSpaceMapper._();

  static const Map<String, String> _defaultSpaceMapping = {
    'start here & introduce yourself': 'start_here',
    'start here': 'start_here',
    'announcements': 'announcements',
    'general chat': 'general_chat',
    'general': 'general_chat',
    'memes': 'memes',
    'meme': 'memes',
    'online resources / videos': 'resources_videos',
    'online resources': 'resources_videos',
    'resources / videos': 'resources_videos',
    'resources': 'resources_videos',
    'actually autistic chat': 'actually_autistic_chat',
    'actually autistic': 'actually_autistic_chat',
    'friends chat': 'friends_chat',
    'friends': 'friends_chat',
    'family chat': 'family_chat',
    'family': 'family_chat',
  };

  /// Section category assigned to each Belong Space slug.
  static const Map<String, String> spaceSections = {
    'start_here': 'Welcome',
    'announcements': 'Welcome',
    'general_chat': 'Community',
    'memes': 'Community',
    'resources_videos': 'Community',
    'actually_autistic_chat': 'Community',
    'friends_chat': 'Community',
    'family_chat': 'Community',
  };

  /// Human-friendly display title for each Belong Space slug.
  static const Map<String, String> spaceDisplayNames = {
    'start_here': 'Start Here & Introduce Yourself',
    'announcements': 'Announcements',
    'general_chat': 'General Chat',
    'memes': 'Memes',
    'resources_videos': 'Online Resources / Videos',
    'actually_autistic_chat': 'Actually Autistic Chat',
    'friends_chat': 'Friends Chat',
    'family_chat': 'Family Chat',
  };

  /// Resolves a Circle.so space name to a canonical Belong space slug.
  /// Returns `'unmapped_space'` if the space is unrecognized.
  static String resolveSpaceSlug(String circleSpaceName, {Map<String, String>? customOverrides}) {
    final normalized = circleSpaceName.trim().toLowerCase();
    if (customOverrides != null && customOverrides.containsKey(normalized)) {
      return customOverrides[normalized]!;
    }
    return _defaultSpaceMapping[normalized] ?? 'unmapped_space';
  }
}

/// An individual parsed community reflection/post record from Circle.so.
class CircleRecord {
  const CircleRecord({
    required this.originalSpaceName,
    required this.belongSpaceSlug,
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorEmail,
    required this.createdAt,
    this.commentsCount = 0,
    this.rawFields = const {},
  });

  final String originalSpaceName;
  final String belongSpaceSlug;
  final String title;
  final String body;
  final String authorName;
  final String authorEmail;
  final DateTime createdAt;
  final int commentsCount;
  final Map<String, String> rawFields;

  /// Returns true if this record has minimum viable content to import.
  bool get isValid =>
      body.trim().isNotEmpty && belongSpaceSlug != 'unmapped_space' && authorName.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'originalSpaceName': originalSpaceName,
    'belongSpaceSlug': belongSpaceSlug,
    'title': title,
    'body': body,
    'authorName': authorName,
    'authorEmail': '[ANONYMIZED_PII]',
    'createdAt': createdAt.toIso8601String(),
    'commentsCount': commentsCount,
  };

  @override
  String toString() =>
      'CircleRecord(space: $belongSpaceSlug, author: $authorName, date: ${createdAt.toIso8601String()})';
}

/// Migration summary report generated after inspecting or importing CSV records.
class CircleImportReport {
  CircleImportReport({
    required this.filePath,
    required this.totalRowsRead,
    required this.validRecordsCount,
    required this.unmappedSpaceCount,
    required this.recordsPerSpace,
    required this.uniqueAuthorsCount,
    required this.earliestDate,
    required this.latestDate,
    required this.isDryRun,
    this.errors = const [],
  });

  final String filePath;
  final int totalRowsRead;
  final int validRecordsCount;
  final int unmappedSpaceCount;
  final Map<String, int> recordsPerSpace;
  final int uniqueAuthorsCount;
  final DateTime? earliestDate;
  final DateTime? latestDate;
  final bool isDryRun;
  final List<String> errors;

  /// Formats an ASCII table suitable for terminal and CI logs.
  String toAsciiTable() {
    final buffer = StringBuffer();
    buffer.writeln('===============================================================');
    buffer.writeln(' 📦 Circle.so CSV Migration Report ${isDryRun ? "(DRY RUN)" : "(APPLIED)"}');
    buffer.writeln('===============================================================');
    buffer.writeln('  Source File:        $filePath');
    buffer.writeln('  Total Rows Read:    $totalRowsRead');
    buffer.writeln('  Valid Records:      $validRecordsCount');
    buffer.writeln('  Unmapped Spaces:    $unmappedSpaceCount');
    buffer.writeln('  Unique Authors:     $uniqueAuthorsCount');
    if (earliestDate != null && latestDate != null) {
      buffer.writeln(
        '  Date Range:         ${earliestDate!.toIso8601String().substring(0, 10)} -> ${latestDate!.toIso8601String().substring(0, 10)}',
      );
    }
    buffer.writeln('---------------------------------------------------------------');
    buffer.writeln('  Space Slug               Section        Count');
    buffer.writeln('---------------------------------------------------------------');
    for (final entry in recordsPerSpace.entries) {
      final slug = entry.key.padRight(24);
      final section = (CircleSpaceMapper.spaceSections[entry.key] ?? 'Other').padRight(14);
      final count = entry.value.toString().padLeft(5);
      buffer.writeln('  $slug $section $count');
    }
    buffer.writeln('===============================================================');
    if (isDryRun) {
      buffer.writeln('  ℹ️  Dry run mode: 0 records written to database.');
      buffer.writeln('  Run without --dry-run to commit records to target database.');
    } else {
      buffer.writeln('  ✅ Successfully imported $validRecordsCount records into database.');
    }
    buffer.writeln('===============================================================');
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'totalRowsRead': totalRowsRead,
    'validRecordsCount': validRecordsCount,
    'unmappedSpaceCount': unmappedSpaceCount,
    'uniqueAuthorsCount': uniqueAuthorsCount,
    'earliestDate': earliestDate?.toIso8601String(),
    'latestDate': latestDate?.toIso8601String(),
    'isDryRun': isDryRun,
    'recordsPerSpace': recordsPerSpace,
    'errors': errors,
  };
}

/// Pure Dart RFC 4180 CSV Parser with quote, comma, multiline, and escaped-quote support.
class CircleCsvParser {
  const CircleCsvParser();

  /// Parses a CSV string into a list of row maps keyed by normalized column header.
  static List<Map<String, String>> parseRows(String csvContent) {
    final rows = <List<String>>[];
    final currentField = StringBuffer();
    final currentRow = <String>[];
    bool inQuotes = false;

    // Normalize Windows CRLF and classic Mac CR to standard LF
    final normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    for (int i = 0; i < normalized.length; i++) {
      final char = normalized[i];

      if (inQuotes) {
        if (char == '"') {
          // Check for escaped quote ("")
          if (i + 1 < normalized.length && normalized[i + 1] == '"') {
            currentField.write('"');
            i++; // skip next quote
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
        } else if (char == '\n') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
          if (currentRow.any((field) => field.isNotEmpty)) {
            rows.add(List<String>.from(currentRow));
          }
          currentRow.clear();
        } else {
          currentField.write(char);
        }
      }
    }

    // Flush any pending field/row
    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      if (currentRow.any((field) => field.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    if (rows.isEmpty) return [];

    // Header extraction
    final headerRow = rows.first;
    final headers = headerRow.map(_normalizeColumnName).toList();

    final result = <Map<String, String>>[];
    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      final recordMap = <String, String>{};
      for (int c = 0; c < headers.length; c++) {
        final key = headers[c];
        final value = c < row.length ? row[c] : '';
        recordMap[key] = value;
      }
      result.add(recordMap);
    }

    return result;
  }

  /// Parses raw CSV rows into strongly typed [CircleRecord] instances.
  static List<CircleRecord> parseRecords(
    String csvContent, {
    Map<String, String>? customSpaceOverrides,
  }) {
    final parsedRows = parseRows(csvContent);
    final records = <CircleRecord>[];

    for (final row in parsedRows) {
      final space = _findField(row, ['space', 'space_name', 'spacename', 'topic']);
      final title = _findField(row, ['title', 'subject', 'post_title', 'name']);
      final body = _findField(row, ['body', 'content', 'post_body', 'text', 'message']);
      final authorName = _findField(row, ['author_name', 'author', 'user_name', 'creator', 'name']);
      final authorEmail = _findField(row, ['author_email', 'email', 'user_email']);
      final dateStr = _findField(row, ['created_at', 'timestamp', 'date', 'posted_at']);

      final belongSlug = CircleSpaceMapper.resolveSpaceSlug(
        space,
        customOverrides: customSpaceOverrides,
      );

      final createdAt = _parseDate(dateStr);

      records.add(
        CircleRecord(
          originalSpaceName: space,
          belongSpaceSlug: belongSlug,
          title: title,
          body: body,
          authorName: authorName.isNotEmpty ? authorName : 'Community Member',
          authorEmail: authorEmail,
          createdAt: createdAt,
          rawFields: row,
        ),
      );
    }

    return records;
  }

  static String _normalizeColumnName(String col) => col
      .replaceAll(RegExp(r'[\s_]+'), '_')
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
      .toLowerCase()
      .trim();

  static String _findField(Map<String, String> row, List<String> candidateKeys) {
    for (final key in candidateKeys) {
      if (row.containsKey(key) && row[key]!.isNotEmpty) {
        return row[key]!;
      }
    }
    return '';
  }

  static DateTime _parseDate(String dateStr) {
    if (dateStr.trim().isEmpty) return DateTime.now().toUtc();

    try {
      // 1. ISO 8601 (e.g. 2026-08-15T14:22:00Z)
      return DateTime.parse(dateStr.trim()).toUtc();
    } catch (_) {}

    try {
      // 2. Standard Circle export format: YYYY-MM-DD HH:MM:SS UTC
      final cleaned = dateStr.replaceAll(' UTC', 'Z').replaceAll(' ', 'T');
      return DateTime.parse(cleaned).toUtc();
    } catch (_) {}

    return DateTime.now().toUtc();
  }
}

/// Orchestrator for loading, validating, and migrating Circle.so exports.
class CircleCsvImporter {
  const CircleCsvImporter();

  /// Analyzes a CSV file and generates an audit report.
  Future<CircleImportReport> analyzeFile(
    String filePath, {
    bool isDryRun = true,
    Map<String, String>? customSpaceOverrides,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Circle CSV export file not found', filePath);
    }

    final content = await file.readAsString();
    return analyzeContent(
      content,
      filePath: filePath,
      isDryRun: isDryRun,
      customSpaceOverrides: customSpaceOverrides,
    );
  }

  /// Analyzes raw CSV content in-memory (useful for unit testing without disk I/O).
  CircleImportReport analyzeContent(
    String csvContent, {
    String filePath = 'in-memory.csv',
    bool isDryRun = true,
    Map<String, String>? customSpaceOverrides,
  }) {
    final records = CircleCsvParser.parseRecords(
      csvContent,
      customSpaceOverrides: customSpaceOverrides,
    );

    int validCount = 0;
    int unmappedCount = 0;
    final spaceCounts = <String, int>{};
    final authorSet = <String>{};
    DateTime? earliest;
    DateTime? latest;

    for (final record in records) {
      if (record.belongSpaceSlug == 'unmapped_space') {
        unmappedCount++;
      } else {
        validCount++;
        spaceCounts[record.belongSpaceSlug] = (spaceCounts[record.belongSpaceSlug] ?? 0) + 1;
      }

      if (record.authorName.isNotEmpty) {
        authorSet.add(record.authorName.toLowerCase());
      }

      if (earliest == null || record.createdAt.isBefore(earliest)) {
        earliest = record.createdAt;
      }
      if (latest == null || record.createdAt.isAfter(latest)) {
        latest = record.createdAt;
      }
    }

    return CircleImportReport(
      filePath: filePath,
      totalRowsRead: records.length,
      validRecordsCount: validCount,
      unmappedSpaceCount: unmappedCount,
      recordsPerSpace: spaceCounts,
      uniqueAuthorsCount: authorSet.length,
      earliestDate: earliest,
      latestDate: latest,
      isDryRun: isDryRun,
    );
  }
}
