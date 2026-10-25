import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Direct client for dispatching confidential member feedback to GitHub Issues.
///
/// Configurable via `--dart-define=FEEDBACK_GITHUB_PAT=github_pat_...` at build time.
/// When no token is configured, falls back gracefully to local/Firestore storage
/// without throwing exceptions or blocking the user.
class GitHubFeedbackClient {
  GitHubFeedbackClient({http.Client? httpClient, String? token})
    : _client = httpClient ?? http.Client(),
      _token =
          token ??
          const String.fromEnvironment('FEEDBACK_GITHUB_PAT', defaultValue: '');

  final http.Client _client;
  final String _token;

  /// Whether a non-empty GitHub Personal Access Token is configured.
  bool get isConfigured => _token.trim().isNotEmpty;

  /// Creates a private triage issue in [repository] (default `neiljaywarner/belong_feedback`).
  ///
  /// Returns a record with the issue number and htmlUrl, or `null` if the request
  /// fails, is rate-limited, or no token is provided.
  Future<({int number, String htmlUrl})?> createIssue({
    required String repository,
    required String title,
    required String body,
    required List<String> labels,
  }) async {
    final token = _token.trim();
    if (token.isEmpty) return null;

    try {
      final response = await _client.post(
        Uri.parse('https://api.github.com/repos/$repository/issues'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'title': title, 'body': body, 'labels': labels}),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final number = json['number'] as int?;
        final url = json['html_url'] as String?;
        if (number != null && url != null) {
          return (number: number, htmlUrl: url);
        }
      }
    } catch (_) {
      // Resilient offline fallback — feedback is preserved in Firestore
    }
    return null;
  }
}

/// Riverpod provider for the [GitHubFeedbackClient].
final gitHubFeedbackClientProvider = Provider<GitHubFeedbackClient>(
  (ref) => GitHubFeedbackClient(),
);
