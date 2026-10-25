import 'dart:convert';
import 'dart:io';

import 'package:refuge4serverpod/src/tool/circle_csv_importer.dart';

/// Pure-Dart CLI tool for validating, auditing, and importing Circle.so CSV
/// community post archives into Belong on the Spectrum before October 31 (#41).
///
/// Usage:
/// ```bash
/// # 1. Validate and generate summary report without modifying database (Dry Run)
/// dart run tool/import_circle_csv.dart --file path/to/circle_posts.csv --dry-run
///
/// # 2. Run with default sample fixture for verification
/// dart run tool/import_circle_csv.dart --dry-run
///
/// # 3. Output machine-readable JSON for CI verification
/// dart run tool/import_circle_csv.dart --dry-run --json
/// ```
Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final isDryRun = args.contains('--dry-run') || !args.contains('--apply');
  final isJson = args.contains('--json');

  String filePath = 'test/fixtures/sample_anonymized_circle_export.csv';
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--file' && i + 1 < args.length) {
      filePath = args[i + 1];
      break;
    }
  }

  final file = File(filePath);
  if (!await file.exists()) {
    stderr.writeln('❌ Error: Circle CSV file not found: $filePath');
    stderr.writeln('Provide a valid CSV path with --file <path>');
    exitCode = 66; // EX_NOINPUT
    return;
  }

  try {
    const importer = CircleCsvImporter();
    final report = await importer.analyzeFile(filePath, isDryRun: isDryRun);

    if (isJson) {
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
    } else {
      stdout.writeln(report.toAsciiTable());
    }

    exitCode = 0;
  } catch (e, stack) {
    stderr.writeln('❌ Fatal error during Circle CSV import: $e');
    stderr.writeln(stack);
    exitCode = 70; // EX_SOFTWARE
  }
}

void _printUsage() {
  stdout.writeln('''
===============================================================
 📦 Belong on the Spectrum — Circle.so CSV Importer (Issue #41)
===============================================================

Usage:
  dart run tool/import_circle_csv.dart [options]

Options:
  --file <path>    Path to Circle.so CSV export file.
                   (Defaults to test/fixtures/sample_anonymized_circle_export.csv)
  --dry-run        Validate format, parse records, and print audit report.
                   Zero records are written to the database. (Default)
  --apply          Commit valid parsed records to the active database.
  --json           Output machine-readable JSON report summary.
  -h, --help       Print this help message.

Canonical Spaces Mapped:
  - "Start Here & Introduce Yourself" -> start_here (Welcome)
  - "Announcements"                   -> announcements (Welcome)
  - "General Chat"                    -> general_chat (Community)
  - "Memes"                           -> memes (Community)
  - "Online Resources / Videos"       -> resources_videos (Community)
  - "Actually Autistic Chat"          -> actually_autistic_chat (Community)
  - "Friends Chat"                    -> friends_chat (Community)
  - "Family Chat"                     -> family_chat (Community)

Zero-PII Rule:
  Real member emails and sensitive identifiers must NEVER be committed to Git.
  Only synthetic, anonymized test fixtures are permitted in repository.
''');
}
