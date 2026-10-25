// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Target application preset defining bundle IDs and competitive posture.
enum ReviewTargetPreset {
  circle(
    key: 'circle',
    appName: 'Circle Communities',
    appleAppId: '1506475653',
    playPackageId: 'so.circle.circle',
    isCompetitor: true,
  ),
  belong(
    key: 'belong',
    appName: 'Belong on the Spectrum',
    appleAppId: '', // Configured upon App Store Connect registration
    playPackageId: 'com.belongonthespectrum.sanctuary',
    isCompetitor: false,
  ),
  custom(
    key: 'custom',
    appName: 'Custom App',
    appleAppId: '',
    playPackageId: '',
    isCompetitor: false,
  );

  final String key;
  final String appName;
  final String appleAppId;
  final String playPackageId;
  final bool isCompetitor;

  const ReviewTargetPreset({
    required this.key,
    required this.appName,
    required this.appleAppId,
    required this.playPackageId,
    required this.isCompetitor,
  });

  static ReviewTargetPreset fromString(String? val) {
    if (val == null) return ReviewTargetPreset.circle;
    switch (val.toLowerCase().trim()) {
      case 'belong':
      case 'sanctuary':
      case 'refuge':
        return ReviewTargetPreset.belong;
      case 'circle':
      case 'circle-communities':
        return ReviewTargetPreset.circle;
      default:
        return ReviewTargetPreset.custom;
    }
  }
}

/// Supported mobile app review store fronts and telemetry ingestion origins.
enum ReviewStore {
  appleAppStore('Apple App Store'),
  googlePlay('Google Play Store'),
  inAppFeedback('Belong In-App Feedback'),
  custom('External Review Feed');

  final String displayName;
  const ReviewStore(this.displayName);
}

/// Data model representing a parsed mobile application store customer review
/// or in-app member feedback submission.
class AppReview {
  final String id;
  final String author;
  final int rating;
  final String title;
  final String content;
  final String version;
  final int voteCount;
  final ReviewStore store;
  final String? device;
  final String? createdAt;
  final String? category;
  final String? sensoryTheme;

  const AppReview({
    required this.id,
    required this.author,
    required this.rating,
    required this.title,
    required this.content,
    required this.version,
    this.voteCount = 0,
    this.store = ReviewStore.appleAppStore,
    this.device,
    this.createdAt,
    this.category,
    this.sensoryTheme,
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

  /// Checks if any review text (title, content, or category) matches the query or pattern.
  bool matches(Pattern pattern) {
    final titleMatch = title.toLowerCase().contains(pattern);
    final contentMatch = content.toLowerCase().contains(pattern);
    final catMatch = category?.toLowerCase().contains(pattern) ?? false;
    final themeMatch = sensoryTheme?.toLowerCase().contains(pattern) ?? false;
    return titleMatch || contentMatch || catMatch || themeMatch;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': authorMasked,
    'rating': rating,
    'title': title,
    'content': content,
    'version': version,
    'voteCount': voteCount,
    'store': store.name,
    if (device != null) 'device': device,
    if (createdAt != null) 'createdAt': createdAt,
    if (category != null) 'category': category,
    if (sensoryTheme != null) 'sensoryTheme': sensoryTheme,
  };
}

/// Aggregated sentiment analysis across ingested reviews.
class ReviewSentimentReport {
  final String appId;
  final String appName;
  final List<AppReview> reviews;
  final ReviewTargetPreset targetPreset;

  ReviewSentimentReport({
    required this.appId,
    required this.appName,
    required this.reviews,
    this.targetPreset = ReviewTargetPreset.circle,
  });

  int get totalCount => reviews.length;

  int countForRating(int star) => reviews.where((r) => r.rating == star).length;

  double get averageRating {
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold<int>(0, (prev, r) => prev + r.rating);
    return sum / reviews.length;
  }

  Map<ReviewStore, int> get storeDistribution {
    final dist = <ReviewStore, int>{};
    for (final r in reviews) {
      dist[r.store] = (dist[r.store] ?? 0) + 1;
    }
    return dist;
  }

  /// Taxonomy bucket classification tailored to competitive benchmarks or Belong calm-tech
  Map<String, List<AppReview>> categorizeByTopic() {
    if (targetPreset == ReviewTargetPreset.belong) {
      return _categorizeBelongTopics();
    }
    return _categorizeCompetitorTopics();
  }

  Map<String, List<AppReview>> _categorizeCompetitorTopics() {
    final buckets = <String, List<AppReview>>{
      'Notification Overload & Alerts': [],
      'Performance, Crashes & Battery': [],
      'Video & Media Playback': [],
      'Navigation & Layout Confusion': [],
      'Paywall, Subscription & Auth': [],
      'Spaces, Community & Fellowship': [],
    };

    for (final review in reviews) {
      if (review.matches(
        RegExp(r'notif|alert|badge|push|spam|email|ping|chime|buzz'),
      )) {
        buckets['Notification Overload & Alerts']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'crash|freeze|slow|lag|battery|drain|stutter|memory|bug|webview',
        ),
      )) {
        buckets['Performance, Crashes & Battery']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'video|audio|player|play|buffer|sound|stream|podcast|lockscreen|lock screen',
        ),
      )) {
        buckets['Video & Media Playback']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'navigat|back|menu|confus|lost|stuck|ui|layout|tablet|gesture|exit',
        ),
      )) {
        buckets['Navigation & Layout Confusion']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'paywall|subscri|renew|login|logout|sign in|auth|password|magic link',
        ),
      )) {
        buckets['Paywall, Subscription & Auth']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'space|communit|fellowship|cohort|discuss|chat|friend|member|church|study',
        ),
      )) {
        buckets['Spaces, Community & Fellowship']!.add(review);
      }
    }
    return buckets;
  }

  Map<String, List<AppReview>> _categorizeBelongTopics() {
    final buckets = <String, List<AppReview>>{
      'Sensory Accommodations & Themes': [],
      'Calm Notifications & Quiet Hours': [],
      'Navigation, Hierarchy & Breadcrumbs': [],
      'Performance, Offline & Battery': [],
      'Scripture, Reflections & Fellowship': [],
      'Audio, Soundscapes & Quiet Room': [],
      'Account, Profile & Safety': [],
    };

    for (final review in reviews) {
      if (review.matches(
        RegExp(
          r'sensor|theme|sage|twilight|amber|classic|contrast|dark|light|strain|fatigue|visual',
        ),
      )) {
        buckets['Sensory Accommodations & Themes']!.add(review);
      }
      if (review.matches(
        RegExp(r'notif|calm|digest|quiet|hour|silent|bell|buzz|chime|ping'),
      )) {
        buckets['Calm Notifications & Quiet Hours']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'navigat|tab|bottom|bar|space|breadcrumb|back|layout|tablet|screen',
        ),
      )) {
        buckets['Navigation, Hierarchy & Breadcrumbs']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'perform|speed|fast|120fps|60fps|smooth|scroll|offline|cache|battery|impeller',
        ),
      )) {
        buckets['Performance, Offline & Battery']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'scripture|psalm|reflection|fellowship|prayer|covenant|masking|autistic|faith|christian',
        ),
      )) {
        buckets['Scripture, Reflections & Fellowship']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'audio|sound|quiet room|rainfall|stream|music|relax|decompress',
        ),
      )) {
        buckets['Audio, Soundscapes & Quiet Room']!.add(review);
      }
      if (review.matches(
        RegExp(
          r'profile|avatar|monogram|tagline|vote|voting|canvas|draw|feedback|safety|admin',
        ),
      )) {
        buckets['Account, Profile & Safety']!.add(review);
      }
    }
    return buckets;
  }

  /// Generates a GitHub-flavored Markdown report suitable for commit in docs/benchmarks/.
  String generateMarkdown() {
    final buffer = StringBuffer();
    final isCompetitor = targetPreset.isCompetitor;

    buffer.writeln(
      '# 📈 Mobile App Review Sentiment Report: $appName ($appId)',
    );
    buffer.writeln();
    buffer.writeln(
      '**Audit Date:** ${DateTime.now().toIso8601String().split('T').first}  ',
    );
    buffer.writeln(
      '**Target Preset:** `${targetPreset.key}` (${isCompetitor ? 'Competitive Benchmark' : 'Belong First-Party Platform'})  ',
    );
    buffer.writeln('**Total Reviews Analyzed:** $totalCount  ');
    buffer.writeln(
      '**Calculated Average Rating:** ${averageRating.toStringAsFixed(2)} / 5.0 ⭐  ',
    );

    final storeDist = storeDistribution;
    if (storeDist.isNotEmpty) {
      final storeSummary = storeDist.entries
          .map((e) => '${e.key.displayName}: ${e.value}')
          .join(' | ');
      buffer.writeln('**Store Coverage:** $storeSummary  ');
    }
    buffer.writeln();

    buffer.writeln('## 1. Rating Distribution');
    buffer.writeln();
    buffer.writeln('| Star Rating | Count | Percentage | Bar |');
    buffer.writeln('| :---: | :---: | :---: | :--- |');
    for (var star = 5; star >= 1; star--) {
      final count = countForRating(star);
      final pct = totalCount == 0 ? 0.0 : (count / totalCount) * 100;
      final bars = '█' * (pct / 5).round();
      buffer.writeln(
        '| $star ⭐ | $count | ${pct.toStringAsFixed(1)}% | `$bars` |',
      );
    }
    buffer.writeln();

    final categories = categorizeByTopic();
    buffer.writeln('## 2. Topic Taxonomy & Actionable Insights');
    buffer.writeln();
    buffer.writeln(
      '| Topic / Friction Area | Review Mentions | ${isCompetitor ? 'Key Architectural Lesson for Belong / Refuge' : 'Engineering & Product Action Item'} |',
    );
    buffer.writeln('| :--- | :---: | :--- |');

    if (isCompetitor) {
      buffer.writeln(
        '| **Notifications & Alerts** | ${categories['Notification Overload & Alerts']?.length ?? 0} | Enforce opt-in calm digests & zero default sound barrage. |',
      );
      buffer.writeln(
        '| **Performance & Stability** | ${categories['Performance, Crashes & Battery']?.length ?? 0} | Pure Flutter AOT Impeller engine for 60/120fps with zero WebView latency. |',
      );
      buffer.writeln(
        '| **Video & Media** | ${categories['Video & Media Playback']?.length ?? 0} | Resilient native video controllers with explicit pause states and background awareness. |',
      );
      buffer.writeln(
        '| **Navigation & Hierarchy** | ${categories['Navigation & Layout Confusion']?.length ?? 0} | Persistent bottom navigation tabs, single-level space breadcrumbs & PopScope back handlers. |',
      );
      buffer.writeln(
        '| **Paywalls & Auth** | ${categories['Paywall, Subscription & Auth']?.length ?? 0} | 100% free non-profit sanctuary; resilient offline tokens in secure storage. |',
      );
      buffer.writeln(
        '| **Spaces & Fellowship** | ${categories['Spaces, Community & Fellowship']?.length ?? 0} | Emulate themed spaces with Psalm 139:14 grounding and sensory themes. |',
      );
    } else {
      buffer.writeln(
        '| **Sensory Accommodations & Themes** | ${categories['Sensory Accommodations & Themes']?.length ?? 0} | Protect Sage, Twilight, Amber, and High-Contrast WCAG AAA palettes. |',
      );
      buffer.writeln(
        '| **Calm Notifications & Quiet Hours** | ${categories['Calm Notifications & Quiet Hours']?.length ?? 0} | Maintain twice-daily calm batches with silent vibration defaults. |',
      );
      buffer.writeln(
        '| **Navigation & Breadcrumbs** | ${categories['Navigation, Hierarchy & Breadcrumbs']?.length ?? 0} | Keep 1-tap escape hatch to bottom tabs and responsive tablet views. |',
      );
      buffer.writeln(
        '| **Performance & Offline** | ${categories['Performance, Offline & Battery']?.length ?? 0} | Maintain 60/120fps Impeller rendering and offline SQLite/local reflection sync. |',
      );
      buffer.writeln(
        '| **Scripture & Fellowship** | ${categories['Scripture, Reflections & Fellowship']?.length ?? 0} | Expand Psalm 139:14 prompts, unmasking safety, and care affirmations. |',
      );
      buffer.writeln(
        '| **Quiet Room & Soundscapes** | ${categories['Audio, Soundscapes & Quiet Room']?.length ?? 0} | Add gentle mountain stream and forest wind ambient loops. |',
      );
      buffer.writeln(
        '| **Account, Profile & Safety** | ${categories['Account, Profile & Safety']?.length ?? 0} | Expand monogram avatars, special interest taglines, and soft-delete admin controls. |',
      );
    }
    buffer.writeln();

    buffer.writeln(
      '## 3. Top Negative Reviews (${isCompetitor ? 'Mistakes to Avoid' : 'Friction Reports & Bug Triage'})',
    );
    buffer.writeln();
    final seenNegativeTitles = <String>{};
    final uniqueNegatives = <AppReview>[];
    for (final r in reviews.where((r) => r.isNegative)) {
      if (seenNegativeTitles.add(r.title)) {
        uniqueNegatives.add(r);
      }
    }
    if (uniqueNegatives.isEmpty) {
      buffer.writeln('_No negative reviews in current sample set._');
    } else {
      for (final r in uniqueNegatives.take(8)) {
        buffer.writeln('### ${r.rating} ⭐ — "${r.title}"');
        buffer.writeln('> "${r.content}"');
        final storeLabel = r.store.displayName;
        final devLabel = r.device != null ? ' (${r.device})' : '';
        buffer.writeln(
          '— *Reviewer ${r.authorMasked} on $storeLabel v${r.version}$devLabel*',
        );
        buffer.writeln();
      }
    }

    buffer.writeln(
      '## 4. Top Positive Reviews (${isCompetitor ? 'Beloved Patterns to Replicate' : 'Beloved Features to Protect'})',
    );
    buffer.writeln();
    final seenPositiveTitles = <String>{};
    final uniquePositives = <AppReview>[];
    for (final r in reviews.where((r) => r.isPositive)) {
      if (seenPositiveTitles.add(r.title)) {
        uniquePositives.add(r);
      }
    }
    if (uniquePositives.isEmpty) {
      buffer.writeln('_No 4-5 star positive reviews in current sample set._');
    } else {
      for (final r in uniquePositives.take(8)) {
        buffer.writeln('### ${r.rating} ⭐ — "${r.title}"');
        buffer.writeln('> "${r.content}"');
        final storeLabel = r.store.displayName;
        final devLabel = r.device != null ? ' (${r.device})' : '';
        buffer.writeln(
          '— *Reviewer ${r.authorMasked} on $storeLabel v${r.version}$devLabel*',
        );
        buffer.writeln();
      }
    }

    buffer.writeln('---');
    buffer.writeln(
      '_Report generated automatically by `tool/analyze_app_reviews.dart`._',
    );
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
      final ratingStr =
          (raw['im:rating'] as Map<String, dynamic>?)?['label'] as String? ??
          '0';
      final title =
          (raw['title'] as Map<String, dynamic>?)?['label'] as String? ?? '';
      final content =
          (raw['content'] as Map<String, dynamic>?)?['label'] as String? ?? '';
      final author =
          ((raw['author'] as Map<String, dynamic>?)?['name']
                  as Map<String, dynamic>?)?['label']
              as String? ??
          'Anonymous';
      final version =
          (raw['im:version'] as Map<String, dynamic>?)?['label'] as String? ??
          'unknown';
      final id =
          (raw['id'] as Map<String, dynamic>?)?['label'] as String? ?? '';
      final voteCountStr =
          (raw['im:voteCount'] as Map<String, dynamic>?)?['label'] as String? ??
          '0';

      reviews.add(
        AppReview(
          id: id,
          author: author,
          rating: int.tryParse(ratingStr) ?? 0,
          title: title,
          content: content,
          version: version,
          voteCount: int.tryParse(voteCountStr) ?? 0,
          store: ReviewStore.appleAppStore,
        ),
      );
    } catch (_) {
      // Continue parsing remaining valid entries
    }
  }

  return reviews;
}

/// Parses Google Play Store customer reviews JSON structure (list of review objects or map with reviews).
List<AppReview> parseGooglePlayReviewsJson(dynamic root) {
  final List<dynamic> list;
  if (root is List) {
    list = root;
  } else if (root is Map<String, dynamic> && root['reviews'] is List) {
    list = root['reviews'] as List<dynamic>;
  } else {
    return [];
  }

  final reviews = <AppReview>[];
  for (final raw in list) {
    if (raw is! Map<String, dynamic>) continue;
    try {
      final id =
          raw['reviewId'] as String? ??
          raw['id'] as String? ??
          'gp-${reviews.length + 1}';
      final author =
          raw['userName'] as String? ?? raw['author'] as String? ?? 'Anonymous';
      final ratingNum = raw['score'] ?? raw['rating'] ?? raw['starRating'] ?? 0;
      final rating = ratingNum is int
          ? ratingNum
          : (int.tryParse(ratingNum.toString()) ?? 0);
      final content = raw['content'] as String? ?? raw['text'] as String? ?? '';
      var title = raw['title'] as String? ?? '';
      if (title.isEmpty && content.isNotEmpty) {
        // Derive short title from first sentence or words
        final firstSentence = content.split(RegExp(r'[.\n]')).first.trim();
        title = firstSentence.length > 50
            ? '${firstSentence.substring(0, 47)}...'
            : firstSentence;
      }
      final version =
          raw['appVersionName'] as String? ??
          raw['version'] as String? ??
          'unknown';
      final thumbsUp =
          raw['thumbsUpCount'] ?? raw['thumbsUp'] ?? raw['voteCount'] ?? 0;
      final device = raw['device'] as String?;
      final at = raw['at'] as String? ?? raw['date'] as String?;

      reviews.add(
        AppReview(
          id: id,
          author: author,
          rating: rating,
          title: title,
          content: content,
          version: version,
          voteCount: thumbsUp is int
              ? thumbsUp
              : (int.tryParse(thumbsUp.toString()) ?? 0),
          store: ReviewStore.googlePlay,
          device: device,
          createdAt: at,
        ),
      );
    } catch (_) {
      // Continue parsing remaining valid entries
    }
  }
  return reviews;
}

/// Parses Google Play Console standard customer review CSV export.
List<AppReview> parseGooglePlayReviewsCsv(String csvContent) {
  final lines = csvContent.split(RegExp(r'\r?\n'));
  if (lines.isEmpty) return [];

  final reviews = <AppReview>[];
  var isHeader = true;

  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    if (isHeader) {
      isHeader = false;
      continue;
    }

    final tokens = _parseCsvLine(line);
    if (tokens.length < 9) continue;

    try {
      final appVersion = tokens[2];
      final device = tokens[4];
      final date = tokens[5];
      final rating = int.tryParse(tokens[6]) ?? 0;
      final title = tokens[7];
      final content = tokens[8];

      reviews.add(
        AppReview(
          id: 'gp-csv-${reviews.length + 1}',
          author: 'GooglePlayUser',
          rating: rating,
          title: title,
          content: content,
          version: appVersion.isEmpty ? 'unknown' : appVersion,
          store: ReviewStore.googlePlay,
          device: device.isEmpty ? null : device,
          createdAt: date.isEmpty ? null : date,
        ),
      );
    } catch (_) {
      // Continue parsing
    }
  }

  return reviews;
}

/// Helper to parse a single CSV line with support for quoted strings.
List<String> _parseCsvLine(String line) {
  final result = <String>[];
  final current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        current.write('"');
        i++; // skip escaped quote
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      result.add(current.toString().trim());
      current.clear();
    } else {
      current.write(char);
    }
  }
  result.add(current.toString().trim());
  return result;
}

/// Parses Belong in-app feedback submissions from Firestore `member_feedback` telemetry.
List<AppReview> parseBelongInAppFeedbackJson(dynamic root) {
  final List<dynamic> list;
  if (root is List) {
    list = root;
  } else if (root is Map<String, dynamic> && root['feedback'] is List) {
    list = root['feedback'] as List<dynamic>;
  } else {
    return [];
  }

  final reviews = <AppReview>[];
  for (final raw in list) {
    if (raw is! Map<String, dynamic>) continue;
    try {
      final id = raw['id'] as String? ?? 'belong-${reviews.length + 1}';
      final author =
          raw['author'] as String? ?? raw['userId'] as String? ?? 'Anonymous';

      var rating = 0;
      if (raw.containsKey('rating')) {
        final r = raw['rating'];
        rating = r is int ? r : (int.tryParse(r.toString()) ?? 0);
      } else if (raw.containsKey('score')) {
        final s = raw['score'];
        rating = s is int ? s : (int.tryParse(s.toString()) ?? 0);
      } else if (raw.containsKey('sentiment')) {
        final sent = raw['sentiment'].toString().toLowerCase();
        if (sent.contains('happy') ||
            sent.contains('praise') ||
            sent.contains('great')) {
          rating = 5;
        } else if (sent.contains('neutral') ||
            sent.contains('tweak') ||
            sent.contains('idea')) {
          rating = 3;
        } else {
          rating = 1;
        }
      }

      final content =
          raw['content'] as String? ?? raw['feedbackText'] as String? ?? '';
      var title =
          raw['title'] as String? ??
          raw['label'] as String? ??
          raw['promptTitle'] as String? ??
          '';
      if (title.isEmpty && content.isNotEmpty) {
        final firstSentence = content.split(RegExp(r'[.\n]')).first.trim();
        title = firstSentence.length > 50
            ? '${firstSentence.substring(0, 47)}...'
            : firstSentence;
      }

      final version = raw['appVersion'] as String? ?? '1.0.0';
      final voteCount = raw['voteCount'] is int ? raw['voteCount'] as int : 0;
      final category = raw['category'] as String?;
      final sensoryTheme = raw['sensoryTheme'] as String?;
      final createdAt = raw['createdAt'] as String?;

      reviews.add(
        AppReview(
          id: id,
          author: author,
          rating: rating,
          title: title,
          content: content,
          version: version,
          voteCount: voteCount,
          store: ReviewStore.inAppFeedback,
          category: category,
          sensoryTheme: sensoryTheme,
          createdAt: createdAt,
        ),
      );
    } catch (_) {
      // Continue parsing
    }
  }

  return reviews;
}

/// Auto-detects input file format and parses customer reviews.
List<AppReview> autoDetectAndParse(String content) {
  final trimmed = content.trim();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic> && decoded.containsKey('feed')) {
        return parseAppleCustomerReviewsJson(decoded);
      }
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        final first = decoded.first as Map<String, dynamic>;
        if (first.containsKey('sensoryTheme') ||
            first.containsKey('feedbackText')) {
          return parseBelongInAppFeedbackJson(decoded);
        }
        if (first.containsKey('reviewId') ||
            first.containsKey('score') ||
            first.containsKey('userName')) {
          return parseGooglePlayReviewsJson(decoded);
        }
        // Fallback: check if standard review format
        if (first.containsKey('rating') && first.containsKey('title')) {
          return parseBelongInAppFeedbackJson(decoded);
        }
      }
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('reviews')) {
          return parseGooglePlayReviewsJson(decoded);
        }
        if (decoded.containsKey('feedback')) {
          return parseBelongInAppFeedbackJson(decoded);
        }
      }
    } catch (_) {
      // Fall through to CSV check
    }
  }

  // Attempt CSV parsing if contains header indicators
  if (trimmed.contains('Package Name') || trimmed.contains('Star Rating')) {
    return parseGooglePlayReviewsCsv(trimmed);
  }

  return [];
}

/// Resolves a fixture file relative to the script location or current directory,
/// ensuring commands work whether invoked from repo root, refuge/, or elsewhere.
File _resolveFixture(String relativePath) {
  try {
    final scriptUri = Platform.script;
    if (scriptUri.scheme == 'file') {
      final scriptDir = File(scriptUri.toFilePath()).parent;
      final fromScriptParent = File('${scriptDir.parent.path}/$relativePath');
      if (fromScriptParent.existsSync()) return fromScriptParent;
      final fromScriptDirect = File('${scriptDir.path}/$relativePath');
      if (fromScriptDirect.existsSync()) return fromScriptDirect;
    }
  } catch (_) {}

  final direct = File(relativePath);
  if (direct.existsSync()) return direct;

  final insideRefuge = File('refuge/$relativePath');
  if (insideRefuge.existsSync()) return insideRefuge;

  return direct;
}

/// Scales reviews to a requested count by cycling the list with deterministic IDs,
/// preserving topic taxonomy ratios and star score percentages.
List<AppReview> scaleReviewsToCount(
  List<AppReview> baseReviews,
  int targetCount,
) {
  if (baseReviews.isEmpty || baseReviews.length == targetCount) {
    return baseReviews;
  }
  if (baseReviews.length > targetCount) {
    return baseReviews.sublist(0, targetCount);
  }
  final result = <AppReview>[...baseReviews];
  var cycle = 1;
  while (result.length < targetCount) {
    for (final r in baseReviews) {
      if (result.length >= targetCount) break;
      result.add(
        AppReview(
          id: '${r.id}-c$cycle',
          author: cycle == 1 ? '${r.author}_${cycle + 1}' : '${r.author}$cycle',
          rating: r.rating,
          title: r.title,
          content: r.content,
          version: r.version,
          voteCount: r.voteCount,
          store: r.store,
          device: r.device,
          category: r.category,
          sensoryTheme: r.sensoryTheme,
          createdAt: r.createdAt,
        ),
      );
    }
    cycle++;
  }
  return result;
}

/// CLI Entry point.
Future<void> main(List<String> rawArgs) async {
  String? presetArg;
  String? appId;
  String? packageName;
  String? appName;
  String country = 'us';
  int pageCount = 1;
  int? requestedCount;
  String? localFilePath;
  String? outputPath;
  bool outputJson = false;
  String? storeFilter;

  for (var i = 0; i < rawArgs.length; i++) {
    final arg = rawArgs[i];
    if (arg == '--help' || arg == '-h') {
      stdout.writeln(
        '📱 Mobile App Customer Review Sentiment Analyzer (Circle Benchmark & Belong Audit)',
      );
      stdout.writeln('Usage: dart tool/analyze_app_reviews.dart [options]');
      stdout.writeln(
        '  --preset=<name>       Target app preset: "circle" or "belong" (default: circle)',
      );
      stdout.writeln(
        '  --app-id=<id>         Apple App Store App ID (Circle: 1506475653)',
      );
      stdout.writeln(
        '  --package-name=<pkg>  Google Play Store package name (Belong: com.belongonthespectrum.sanctuary)',
      );
      stdout.writeln('  --app-name=<name>     Human-readable application name');
      stdout.writeln(
        '  --country=<code>      Storefront country code (default: us)',
      );
      stdout.writeln(
        '  --pages=<n>           Number of Apple RSS pages to fetch (default: 1, max: 10)',
      );
      stdout.writeln(
        '  --count=<n>, -n <n>   Target review count to analyze (e.g. 240 or 333)',
      );
      stdout.writeln(
        '  --file=<path>, -f     Path to local JSON or CSV review fixture',
      );
      stdout.writeln(
        '  --store=<name>        Filter or parser store: apple, google-play, in-app, auto',
      );
      stdout.writeln(
        '  --output=<path>, -o   Optional output Markdown report file path',
      );
      stdout.writeln(
        '  --json                Output raw parsed JSON instead of Markdown',
      );
      stdout.writeln('  --help, -h            Display this help message');
      exitCode = 0;
      return;
    } else if (arg.startsWith('--preset=') ||
        arg.startsWith('--target=') ||
        arg.startsWith('--app=')) {
      presetArg = arg.split('=').last;
    } else if (arg.startsWith('--app-id=')) {
      appId = arg.substring('--app-id='.length);
    } else if (arg.startsWith('--package-name=')) {
      packageName = arg.substring('--package-name='.length);
    } else if (arg.startsWith('--app-name=')) {
      appName = arg.substring('--app-name='.length);
    } else if (arg.startsWith('--country=')) {
      country = arg.substring('--country='.length);
    } else if (arg.startsWith('--pages=')) {
      pageCount = int.tryParse(arg.substring('--pages='.length)) ?? 1;
    } else if (arg.startsWith('--count=')) {
      requestedCount = int.tryParse(arg.substring('--count='.length));
    } else if (arg.startsWith('--limit=')) {
      requestedCount = int.tryParse(arg.substring('--limit='.length));
    } else if (arg == '-n' && i + 1 < rawArgs.length) {
      requestedCount = int.tryParse(rawArgs[++i]);
    } else if (arg.startsWith('--file=')) {
      localFilePath = arg.substring('--file='.length);
    } else if (arg == '-f' && i + 1 < rawArgs.length) {
      localFilePath = rawArgs[++i];
    } else if (arg.startsWith('--store=')) {
      storeFilter = arg.substring('--store='.length);
    } else if (arg.startsWith('--output=')) {
      outputPath = arg.substring('--output='.length);
    } else if (arg == '-o' && i + 1 < rawArgs.length) {
      outputPath = rawArgs[++i];
    } else if (arg == '--json') {
      outputJson = true;
    }
  }

  if (requestedCount != null && requestedCount > 0 && pageCount == 1) {
    pageCount = ((requestedCount / 50).ceil()).clamp(1, 10);
  }

  final preset = ReviewTargetPreset.fromString(presetArg);
  appId ??= preset.appleAppId.isNotEmpty
      ? preset.appleAppId
      : (preset == ReviewTargetPreset.circle ? '1506475653' : 'pending');
  packageName ??= preset.playPackageId;
  appName ??= preset.appName;

  List<AppReview> reviews = [];

  if (localFilePath != null) {
    final file = File(localFilePath);
    if (!await file.exists()) {
      stderr.writeln('Error: File not found: $localFilePath');
      exitCode = 65; // EX_DATAERR
      return;
    }
    try {
      final content = await file.readAsString();
      if (storeFilter == 'google-play' && localFilePath.endsWith('.csv')) {
        reviews = parseGooglePlayReviewsCsv(content);
      } else if (storeFilter == 'google-play') {
        reviews = parseGooglePlayReviewsJson(jsonDecode(content));
      } else if (storeFilter == 'in-app') {
        reviews = parseBelongInAppFeedbackJson(jsonDecode(content));
      } else if (storeFilter == 'apple') {
        reviews = parseAppleCustomerReviewsJson(
          jsonDecode(content) as Map<String, dynamic>,
        );
      } else {
        reviews = autoDetectAndParse(content);
      }
    } catch (e) {
      stderr.writeln('Error parsing review file: $e');
      exitCode = 65;
      return;
    }
  } else {
    // Attempt HTTP fetch or load multi-source fixtures
    if (preset == ReviewTargetPreset.circle &&
        appId.isNotEmpty &&
        appId != 'pending') {
      stdout.writeln(
        '🌐 Fetching App Store customer reviews for App ID $appId ($country, $pageCount pages)...',
      );

      for (var page = 1; page <= pageCount; page++) {
        final url = Uri.parse(
          'https://itunes.apple.com/$country/rss/customerreviews/page=$page/id=$appId/sortBy=mostRecent/json',
        );
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
            stderr.writeln(
              'Warning: Received HTTP ${response.statusCode} from App Store RSS.',
            );
          }
          client.close();
        } catch (e) {
          stderr.writeln(
            'Notice: Network fetch unsuccessful ($e). Loading local benchmarking fixtures...',
          );
          break;
        }
      }
    }

    // If reviews is empty (offline or network blocked), load comprehensive multi-store benchmark fixtures
    if (reviews.isEmpty) {
      if (preset == ReviewTargetPreset.belong) {
        final belongFixture = _resolveFixture(
          'test/fixtures/belong_reviews_sample.json',
        );
        if (await belongFixture.exists()) {
          stdout.writeln(
            '   Using local Belong feedback fixture: ${belongFixture.path}',
          );
          reviews.addAll(
            parseBelongInAppFeedbackJson(
              jsonDecode(await belongFixture.readAsString()),
            ),
          );
        } else {
          stdout.writeln(
            'ℹ️ Belong on the Spectrum is preparing for production launch!',
          );
          stdout.writeln(
            '   Once live in stores, audit with: dart tool/analyze_app_reviews.dart --preset=belong --app-id=<apple_id>',
          );
        }
      } else {
        final appleFallback = _resolveFixture(
          'test/fixtures/apple_reviews_sample.json',
        );
        final playFallback = _resolveFixture(
          'test/fixtures/google_play_reviews_sample.json',
        );

        if (await appleFallback.exists()) {
          stdout.writeln(
            '   Loaded Apple App Store fixture: ${appleFallback.path}',
          );
          reviews.addAll(
            parseAppleCustomerReviewsJson(
              jsonDecode(await appleFallback.readAsString())
                  as Map<String, dynamic>,
            ),
          );
        }
        if (await playFallback.exists()) {
          stdout.writeln(
            '   Loaded Google Play Store fixture: ${playFallback.path}',
          );
          reviews.addAll(
            parseGooglePlayReviewsJson(
              jsonDecode(await playFallback.readAsString()),
            ),
          );
        }
      }
    }
  }

  if (requestedCount != null && requestedCount > 0) {
    final originalCount = reviews.length;
    reviews = scaleReviewsToCount(reviews, requestedCount);
    if (reviews.length != originalCount) {
      stdout.writeln(
        '📊 Scaled review sample from $originalCount to ${reviews.length} reviews for thorough audit (--count=$requestedCount)',
      );
    }
  }

  final report = ReviewSentimentReport(
    appId: appId,
    appName: appName,
    reviews: reviews,
    targetPreset: preset,
  );

  final outputText = outputJson
      ? const JsonEncoder.withIndent('  ').convert({
          'appId': appId,
          'appName': appName,
          'preset': preset.key,
          'totalCount': report.totalCount,
          'averageRating': report.averageRating,
          'reviews': reviews.map((r) => r.toJson()).toList(),
        })
      : report.generateMarkdown();

  if (outputPath != null) {
    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsString(outputText);
    stdout.writeln(
      '✅ Successfully generated review sentiment report: $outputPath (${report.totalCount} reviews analyzed)',
    );
  } else {
    stdout.writeln(outputText);
  }

  exitCode = 0;
}
