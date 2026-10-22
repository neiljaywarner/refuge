// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Data model representing a parsed mobile application store customer review.
class AppReview {
  final String id;
  final String author;
  final int rating;
  final String title;
  final String content;
  final String version;
  final int voteCount;

  const AppReview({
    required this.id,
    required this.author,
    required this.rating,
    required this.title,
    required this.content,
    required this.version,
    this.voteCount = 0,
  });

  /// True if the review expresses positive satisfaction (4 or 5 stars).
  bool get isPositive => rating >= 4;

  /// True if the review expresses negative frustration / friction (1 or 2 stars).
  bool get isNegative => rating <= 2;

  /// True if neutral (3 stars).
  bool get isNeutral => rating == 3;

  /// Anonymized, Zero-PII safe author name (e.g. "C***r" or "User_***").
  String get authorMasked {
    final clean = author.trim();
    if (clean.isEmpty) return 'Anonymous';
    if (clean.length <= 2) return '${clean[0]}*';
    return '${clean[0]}${'*' * (clean.length - 2)}${clean[clean.length - 1]}';
  }

  /// Checks if any review text (title or content) matches the query or pattern.
  bool matches(Pattern pattern) {
    return title.toLowerCase().contains(pattern) ||
        content.toLowerCase().contains(pattern);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': authorMasked,
        'rating': rating,
        'title': title,
        'content': content,
        'version': version,
        'voteCount': voteCount,
      };
}

/// Aggregated sentiment analysis across ingested reviews.
class ReviewSentimentReport {
  final String appId;
  final String appName;
  final List<AppReview> reviews;

  ReviewSentimentReport({
    required this.appId,
    required this.appName,
    required this.reviews,
  });

  int get totalCount => reviews.length;

  int countForRating(int star) =>
      reviews.where((r) => r.rating == star).length;

  double get averageRating {
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold<int>(0, (prev, r) => prev + r.rating);
    return sum / reviews.length;
  }

  /// Taxonomy bucket classification
  Map<String, List<AppReview>> categorizeByTopic() {
    final buckets = <String, List<AppReview>>{
      'Notification Overload & Alerts': [],
      'Performance, Crashes & Battery': [],
      'Video & Media Playback': [],
      'Navigation & Layout Confusion': [],
      'Paywall, Subscription & Auth': [],
      'Spaces, Community & Fellowship': [],
    };

    for (final review in reviews) {
      if (review.matches(RegExp(r'notif|alert|badge|push|spam|email|ping'))) {
        buckets['Notification Overload & Alerts']!.add(review);
      }
      if (review.matches(RegExp(r'crash|freeze|slow|lag|battery|drain|stutter|memory|bug'))) {
        buckets['Performance, Crashes & Battery']!.add(review);
      }
      if (review.matches(RegExp(r'video|audio|player|play|buffer|sound|stream'))) {
        buckets['Video & Media Playback']!.add(review);
      }
      if (review.matches(RegExp(r'navigat|back|menu|confus|lost|stuck|ui|layout'))) {
        buckets['Navigation & Layout Confusion']!.add(review);
      }
      if (review.matches(RegExp(r'paywall|subscri|renew|login|logout|sign in|auth|password'))) {
        buckets['Paywall, Subscription & Auth']!.add(review);
      }
      if (review.matches(RegExp(r'space|communit|fellowship|cohort|discuss|chat|friend|member'))) {
        buckets['Spaces, Community & Fellowship']!.add(review);
      }
    }
    return buckets;
  }

  /// Generates a GitHub-flavored Markdown report suitable for commit in docs/benchmarks/.
  String generateMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# 📈 Mobile App Review Sentiment Report: $appName ($appId)');
    buffer.writeln();
    buffer.writeln('**Audit Date:** ${DateTime.now().toIso8601String().split('T').first}  ');
    buffer.writeln('**Total Reviews Analyzed:** $totalCount  ');
    buffer.writeln('**Calculated Average Rating:** ${averageRating.toStringAsFixed(2)} / 5.0 ⭐  ');
    buffer.writeln();

    buffer.writeln('## 1. Rating Distribution');
    buffer.writeln();
    buffer.writeln('| Star Rating | Count | Percentage | Bar |');
    buffer.writeln('| :---: | :---: | :---: | :--- |');
    for (var star = 5; star >= 1; star--) {
      final count = countForRating(star);
      final pct = totalCount == 0 ? 0.0 : (count / totalCount) * 100;
      final bars = '█' * (pct / 5).round();
      buffer.writeln('| $star ⭐ | $count | ${pct.toStringAsFixed(1)}% | `$bars` |');
    }
    buffer.writeln();

    final categories = categorizeByTopic();
    buffer.writeln('## 2. Competitive Topic Taxonomy Analysis');
    buffer.writeln();
    buffer.writeln('| Topic / Friction Area | Review Mentions | Key Architectural Lesson for Belong / Refuge |');
    buffer.writeln('| :--- | :---: | :--- |');
    buffer.writeln('| **Notifications & Alerts** | ${categories['Notification Overload & Alerts']!.length} | Enforce opt-in calm digests & zero default sound barrage. |');
    buffer.writeln('| **Performance & Stability** | ${categories['Performance, Crashes & Battery']!.length} | Pure Flutter AOT Impeller engine for 60/120fps with zero WebView latency. |');
    buffer.writeln('| **Video & Media** | ${categories['Video & Media Playback']!.length} | Resilient native video controllers with explicit pause states and background awareness. |');
    buffer.writeln('| **Navigation & Hierarchy** | ${categories['Navigation & Layout Confusion']!.length} | Persistent bottom navigation tabs and single-level space breadcrumbs. |');
    buffer.writeln('| **Paywalls & Auth** | ${categories['Paywall, Subscription & Auth']!.length} | 100% free non-profit sanctuary; resilient offline tokens in secure storage. |');
    buffer.writeln('| **Spaces & Fellowship** | ${categories['Spaces, Community & Fellowship']!.length} | Emulate themed spaces with Psalm 139:14 grounding and sensory themes. |');
    buffer.writeln();

    buffer.writeln('## 3. Top Negative Reviews (Mistakes to Avoid)');
    buffer.writeln();
    final negatives = reviews.where((r) => r.isNegative).toList();
    if (negatives.isEmpty) {
      buffer.writeln('_No negative reviews in current sample set._');
    } else {
      for (final r in negatives) {
        buffer.writeln('### ${r.rating} ⭐ — "${r.title}"');
        buffer.writeln('> "${r.content}"');
        buffer.writeln('— *Reviewer ${r.authorMasked} (v${r.version})*');
        buffer.writeln();
      }
    }

    buffer.writeln('## 4. Top Positive Reviews (Beloved Patterns to Replicate)');
    buffer.writeln();
    final positives = reviews.where((r) => r.isPositive).toList();
    if (positives.isEmpty) {
      buffer.writeln('_No 4-5 star positive reviews in current sample set._');
    } else {
      for (final r in positives) {
        buffer.writeln('### ${r.rating} ⭐ — "${r.title}"');
        buffer.writeln('> "${r.content}"');
        buffer.writeln('— *Reviewer ${r.authorMasked} (v${r.version})*');
        buffer.writeln();
      }
    }

    buffer.writeln('---');
    buffer.writeln('_Report generated automatically by `tool/analyze_app_reviews.dart`._');
    return buffer.toString();
  }
}

/// Parses standard Apple App Store RSS customer reviews JSON structure.
List<AppReview> parseAppleCustomerReviewsJson(Map<String, dynamic> root) {
  final feed = root['feed'] as Map<String, dynamic>?;
  if (feed == null) return [];

  final entries = feed['entry'];
  if (entries == null) return [];

  final reviews = <AppReview>[];
  final rawList = entries is List ? entries : [entries];

  for (final raw in rawList) {
    if (raw is! Map<String, dynamic>) continue;
    // Entry 0 in Apple RSS feed is frequently the App Store metadata entry without im:rating.
    if (!raw.containsKey('im:rating')) continue;

    try {
      final ratingStr = (raw['im:rating'] as Map<String, dynamic>?)?['label'] as String? ?? '0';
      final title = (raw['title'] as Map<String, dynamic>?)?['label'] as String? ?? '';
      final content = (raw['content'] as Map<String, dynamic>?)?['label'] as String? ?? '';
      final author = ((raw['author'] as Map<String, dynamic>?)?['name'] as Map<String, dynamic>?)?['label'] as String? ?? 'Anonymous';
      final version = (raw['im:version'] as Map<String, dynamic>?)?['label'] as String? ?? 'unknown';
      final id = (raw['id'] as Map<String, dynamic>?)?['label'] as String? ?? '';
      final voteCountStr = (raw['im:voteCount'] as Map<String, dynamic>?)?['label'] as String? ?? '0';

      reviews.add(AppReview(
        id: id,
        author: author,
        rating: int.tryParse(ratingStr) ?? 0,
        title: title,
        content: content,
        version: version,
        voteCount: int.tryParse(voteCountStr) ?? 0,
      ));
    } catch (_) {
      // Continue parsing remaining valid entries
    }
  }

  return reviews;
}

/// CLI Entry point.
Future<void> main(List<String> rawArgs) async {
  String appId = '1506475653';
  String country = 'us';
  int pageCount = 1;
  String? localFilePath;
  String? outputPath;
  bool outputJson = false;

  for (var i = 0; i < rawArgs.length; i++) {
    final arg = rawArgs[i];
    if (arg == '--help' || arg == '-h') {
      stdout.writeln('📱 App Store Customer Review Sentiment Analyzer (Circle Benchmarking)');
      stdout.writeln('Usage: dart tool/analyze_app_reviews.dart [options]');
      stdout.writeln('  --app-id=<id>    Apple App Store App ID (Circle: 1506475653)');
      stdout.writeln('  --country=<code> Storefront country code (default: us)');
      stdout.writeln('  --pages=<n>      Number of RSS pages to fetch (default: 1)');
      stdout.writeln('  --file=<path>    Path to local JSON review fixture');
      stdout.writeln('  --output=<path>  Optional output Markdown report file path');
      stdout.writeln('  --json           Output raw parsed JSON instead of Markdown');
      stdout.writeln('  --help, -h       Display this help message');
      exitCode = 0;
      return;
    } else if (arg.startsWith('--app-id=')) {
      appId = arg.substring('--app-id='.length);
    } else if (arg.startsWith('--country=')) {
      country = arg.substring('--country='.length);
    } else if (arg.startsWith('--pages=')) {
      pageCount = int.tryParse(arg.substring('--pages='.length)) ?? 1;
    } else if (arg.startsWith('--file=')) {
      localFilePath = arg.substring('--file='.length);
    } else if (arg == '-f' && i + 1 < rawArgs.length) {
      localFilePath = rawArgs[++i];
    } else if (arg.startsWith('--output=')) {
      outputPath = arg.substring('--output='.length);
    } else if (arg == '-o' && i + 1 < rawArgs.length) {
      outputPath = rawArgs[++i];
    } else if (arg == '--json') {
      outputJson = true;
    }
  }

  List<AppReview> reviews = [];

  if (localFilePath != null) {
    final file = File(localFilePath);
    if (!await file.exists()) {
      stderr.writeln('Error: File not found: $localFilePath');
      exitCode = 65; // EX_DATAERR
      return;
    }
    try {
      final jsonContent = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      reviews = parseAppleCustomerReviewsJson(jsonContent);
    } catch (e) {
      stderr.writeln('Error parsing JSON fixture: $e');
      exitCode = 65;
      return;
    }
  } else {
    // Attempt HTTP fetch from Apple App Store RSS
    stdout.writeln('🌐 Fetching App Store customer reviews for App ID $appId ($country, $pageCount pages)...');

    for (var page = 1; page <= pageCount; page++) {
      final url = Uri.parse('https://itunes.apple.com/$country/rss/customerreviews/page=$page/id=$appId/sortBy=mostRecent/json');
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        final request = await client.getUrl(url);
        final response = await request.close();
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          reviews.addAll(parseAppleCustomerReviewsJson(decoded));
        } else {
          stderr.writeln('Warning: Received HTTP ${response.statusCode} from App Store RSS.');
        }
        client.close();
      } catch (e) {
        stderr.writeln('Notice: Network fetch unsuccessful ($e). Checking for fallback fixture...');
        // Safe fallback to test fixture if present
        final fallback = File('test/fixtures/apple_reviews_sample.json');
        if (await fallback.exists()) {
          stdout.writeln('   Using local fallback fixture: ${fallback.path}');
          final decoded = jsonDecode(await fallback.readAsString()) as Map<String, dynamic>;
          reviews = parseAppleCustomerReviewsJson(decoded);
          break;
        }
      }
    }
  }

  final report = ReviewSentimentReport(
    appId: appId,
    appName: 'Circle Communities',
    reviews: reviews,
  );

  final outputText = outputJson
      ? const JsonEncoder.withIndent('  ').convert({
          'appId': appId,
          'totalCount': report.totalCount,
          'averageRating': report.averageRating,
          'reviews': reviews.map((r) => r.toJson()).toList(),
        })
      : report.generateMarkdown();

  if (outputPath != null) {
    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsString(outputText);
    stdout.writeln('✅ Successfully generated review sentiment report: $outputPath (${report.totalCount} reviews)');
  } else {
    stdout.writeln(outputText);
  }

  exitCode = 0;
}
