import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Since tool/analyze_app_reviews.dart is a CLI script, we can test its models and parsing logic.
// We import via relative path to the tool script.
import '../../tool/analyze_app_reviews.dart';

void main() {
  group('ReviewTargetPreset', () {
    test('correctly maps string flags to presets', () {
      expect(ReviewTargetPreset.fromString('circle'), equals(ReviewTargetPreset.circle));
      expect(
        ReviewTargetPreset.fromString('circle-communities'),
        equals(ReviewTargetPreset.circle),
      );
      expect(ReviewTargetPreset.fromString('belong'), equals(ReviewTargetPreset.belong));
      expect(ReviewTargetPreset.fromString('sanctuary'), equals(ReviewTargetPreset.belong));
      expect(ReviewTargetPreset.fromString('refuge'), equals(ReviewTargetPreset.belong));
      expect(ReviewTargetPreset.fromString('otherApp'), equals(ReviewTargetPreset.custom));
      expect(ReviewTargetPreset.fromString(null), equals(ReviewTargetPreset.circle));
    });

    test('preset metadata matches platform configurations', () {
      expect(ReviewTargetPreset.belong.playPackageId, equals('com.belongonthespectrum.sanctuary'));
      expect(ReviewTargetPreset.belong.appName, equals('Belong on the Spectrum'));
      expect(ReviewTargetPreset.belong.isCompetitor, isFalse);

      expect(ReviewTargetPreset.circle.playPackageId, equals('so.circle.circle'));
      expect(ReviewTargetPreset.circle.appleAppId, equals('1506475653'));
      expect(ReviewTargetPreset.circle.appName, equals('Circle Communities'));
      expect(ReviewTargetPreset.circle.isCompetitor, isTrue);
    });
  });

  group('AppReview Model & PII Masking', () {
    test('accurately classifies positive, negative, and neutral sentiment', () {
      const positive5 = AppReview(
        id: '1',
        author: 'UserOne',
        rating: 5,
        title: 'Wonderful app',
        content: 'Loved the spaces',
        version: '1.0',
      );
      const positive4 = AppReview(
        id: '2',
        author: 'UserTwo',
        rating: 4,
        title: 'Great',
        content: 'Good community',
        version: '1.0',
      );
      const neutral3 = AppReview(
        id: '3',
        author: 'UserThree',
        rating: 3,
        title: 'Okay',
        content: 'Decent',
        version: '1.0',
      );
      const negative2 = AppReview(
        id: '4',
        author: 'UserFour',
        rating: 2,
        title: 'Buggy',
        content: 'Video freeze',
        version: '1.0',
      );
      const negative1 = AppReview(
        id: '5',
        author: 'UserFive',
        rating: 1,
        title: 'Horrible',
        content: 'Notification spam',
        version: '1.0',
      );

      expect(positive5.isPositive, isTrue);
      expect(positive5.isNegative, isFalse);

      expect(positive4.isPositive, isTrue);
      expect(positive4.isNegative, isFalse);

      expect(neutral3.isNeutral, isTrue);
      expect(neutral3.isPositive, isFalse);
      expect(neutral3.isNegative, isFalse);

      expect(negative2.isNegative, isTrue);
      expect(negative2.isPositive, isFalse);

      expect(negative1.isNegative, isTrue);
      expect(negative1.isPositive, isFalse);
    });

    test('protects reviewer privacy with Zero-PII author masking', () {
      const review1 = AppReview(
        id: '1',
        author: 'JohnDoe',
        rating: 5,
        title: 'Test',
        content: 'Content',
        version: '1.0',
      );
      expect(review1.authorMasked, equals('J*****e'));

      const review2 = AppReview(
        id: '2',
        author: 'Al',
        rating: 4,
        title: 'Test',
        content: 'Content',
        version: '1.0',
      );
      expect(review2.authorMasked, equals('A*'));

      const review3 = AppReview(
        id: '3',
        author: '   ',
        rating: 4,
        title: 'Test',
        content: 'Content',
        version: '1.0',
      );
      expect(review3.authorMasked, equals('Anonymous'));
    });
  });

  group('Apple Customer Reviews JSON Parsing', () {
    test('parses Apple RSS feed and skips index 0 header metadata entry', () async {
      final sampleFile = File('test/fixtures/apple_reviews_sample.json');
      expect(await sampleFile.exists(), isTrue, reason: 'Sample fixture must exist');

      final jsonContent = jsonDecode(await sampleFile.readAsString()) as Map<String, dynamic>;
      final reviews = parseAppleCustomerReviewsJson(jsonContent);

      expect(reviews.length, equals(30));

      final first = reviews.first;
      expect(first.id, equals('rev-001'));
      expect(first.rating, equals(1));
      expect(first.title, contains('Notification spam'));
      expect(first.version, equals('3.12.0'));
      expect(first.isNegative, isTrue);
      expect(first.store, equals(ReviewStore.appleAppStore));

      final fifth = reviews[4];
      expect(fifth.id, equals('rev-005'));
      expect(fifth.rating, equals(5));
      expect(fifth.title, contains('Best community platform'));
      expect(fifth.isPositive, isTrue);
    });
  });

  group('Google Play Store Reviews Parsing', () {
    test('parses Google Play JSON reviews structure', () async {
      final sampleFile = File('test/fixtures/google_play_reviews_sample.json');
      expect(await sampleFile.exists(), isTrue);

      final jsonContent = jsonDecode(await sampleFile.readAsString());
      final reviews = parseGooglePlayReviewsJson(jsonContent);

      expect(reviews.length, equals(30));

      final first = reviews.first;
      expect(first.id, equals('gp-001'));
      expect(first.rating, equals(1));
      expect(first.title, contains('System back button'));
      expect(first.device, equals('Google Pixel 9a'));
      expect(first.store, equals(ReviewStore.googlePlay));
      expect(first.isNegative, isTrue);

      final autisticReview = reviews.firstWhere((r) => r.id == 'gp-025');
      expect(autisticReview.rating, equals(5));
      expect(autisticReview.title, contains('Discord'));
      expect(autisticReview.isPositive, isTrue);
    });

    test('parses Google Play CSV export structure', () async {
      final sampleFile = File('test/fixtures/google_play_reviews_sample.csv');
      expect(await sampleFile.exists(), isTrue);

      final csvContent = await sampleFile.readAsString();
      final reviews = parseGooglePlayReviewsCsv(csvContent);

      expect(reviews.length, equals(10));
      expect(reviews.first.rating, equals(1));
      expect(reviews.first.title, contains('System back button'));
      expect(reviews.first.store, equals(ReviewStore.googlePlay));
    });
  });

  group('Belong In-App Feedback Parsing', () {
    test('parses Belong on the Spectrum feedback submissions', () async {
      final sampleFile = File('test/fixtures/belong_reviews_sample.json');
      expect(await sampleFile.exists(), isTrue);

      final jsonContent = jsonDecode(await sampleFile.readAsString());
      final reviews = parseBelongInAppFeedbackJson(jsonContent);

      expect(reviews.length, equals(20));

      final first = reviews.first;
      expect(first.id, equals('belong-rev-001'));
      expect(first.rating, equals(5));
      expect(first.title, contains('Muted Sage'));
      expect(first.sensoryTheme, equals('sage'));
      expect(first.category, equals('sensory'));
      expect(first.store, equals(ReviewStore.inAppFeedback));
      expect(first.isPositive, isTrue);

      final quietRoomReview = reviews.firstWhere((r) => r.id == 'belong-rev-003');
      expect(quietRoomReview.content, contains('Psalm 139:14'));
      expect(quietRoomReview.title, contains('Quiet Room'));
    });
  });

  group('Auto-Detect Ingestion Format', () {
    test(
      'auto-detects and parses Apple RSS, Google Play JSON, Play CSV and Belong feedback',
      () async {
        final apple = await File('test/fixtures/apple_reviews_sample.json').readAsString();
        final playJson = await File('test/fixtures/google_play_reviews_sample.json').readAsString();
        final playCsv = await File('test/fixtures/google_play_reviews_sample.csv').readAsString();
        final belong = await File('test/fixtures/belong_reviews_sample.json').readAsString();

        expect(autoDetectAndParse(apple).length, equals(30));
        expect(autoDetectAndParse(playJson).length, equals(30));
        expect(autoDetectAndParse(playCsv).length, equals(10));
        expect(autoDetectAndParse(belong).length, equals(20));
      },
    );
  });

  group('Multi-Store Competitive Sentiment Report (Circle 60 reviews)', () {
    test('generates comprehensive combined report across Apple & Google Play', () async {
      final appleJson = jsonDecode(
        await File('test/fixtures/apple_reviews_sample.json').readAsString(),
      ) as Map<String, dynamic>;
      final playJson = jsonDecode(
        await File('test/fixtures/google_play_reviews_sample.json').readAsString(),
      );

      final allReviews = [
        ...parseAppleCustomerReviewsJson(appleJson),
        ...parseGooglePlayReviewsJson(playJson),
      ];

      expect(allReviews.length, equals(60));

      final report = ReviewSentimentReport(
        appId: '1506475653 / so.circle.circle',
        appName: 'Circle Communities',
        reviews: allReviews,
        targetPreset: ReviewTargetPreset.circle,
      );

      expect(report.totalCount, equals(60));
      expect(report.storeDistribution[ReviewStore.appleAppStore], equals(30));
      expect(report.storeDistribution[ReviewStore.googlePlay], equals(30));

      final categories = report.categorizeByTopic();
      expect(categories['Notification Overload & Alerts']!.length, greaterThanOrEqualTo(5));
      expect(categories['Performance, Crashes & Battery']!.length, greaterThanOrEqualTo(5));
      expect(categories['Video & Media Playback']!.length, greaterThanOrEqualTo(4));
      expect(categories['Navigation & Layout Confusion']!.length, greaterThanOrEqualTo(5));
      expect(categories['Paywall, Subscription & Auth']!.length, greaterThanOrEqualTo(2));
      expect(categories['Spaces, Community & Fellowship']!.length, greaterThanOrEqualTo(10));

      final markdown = report.generateMarkdown();
      expect(markdown, contains('# 📈 Mobile App Review Sentiment Report: Circle Communities'));
      expect(markdown, contains('Competitive Benchmark'));
      expect(markdown, contains('Total Reviews Analyzed:** 60'));
      expect(markdown, contains('Key Architectural Lesson for Belong / Refuge'));
      expect(markdown, contains('Mistakes to Avoid'));
      expect(markdown, contains('Beloved Patterns to Replicate'));
      expect(markdown, contains('Apple App Store: 30'));
      expect(markdown, contains('Google Play Store: 30'));
    });
  });

  group('First-Party Belong Sentiment Report (Belong 20 reviews)', () {
    test('generates Belong-tailored calm-tech taxonomy report', () async {
      final belongJson = jsonDecode(
        await File('test/fixtures/belong_reviews_sample.json').readAsString(),
      );
      final reviews = parseBelongInAppFeedbackJson(belongJson);

      final report = ReviewSentimentReport(
        appId: 'com.belongonthespectrum.sanctuary',
        appName: 'Belong on the Spectrum',
        reviews: reviews,
        targetPreset: ReviewTargetPreset.belong,
      );

      expect(report.totalCount, equals(20));
      expect(report.averageRating, closeTo(4.4, 0.01));

      final categories = report.categorizeByTopic();
      expect(categories['Sensory Accommodations & Themes']!.length, greaterThanOrEqualTo(4));
      expect(categories['Calm Notifications & Quiet Hours']!.length, greaterThanOrEqualTo(1));
      expect(categories['Audio, Soundscapes & Quiet Room']!.length, greaterThanOrEqualTo(2));
      expect(categories['Scripture, Reflections & Fellowship']!.length, greaterThanOrEqualTo(5));

      final markdown = report.generateMarkdown();
      expect(markdown, contains('# 📈 Mobile App Review Sentiment Report: Belong on the Spectrum'));
      expect(markdown, contains('Belong First-Party Platform'));
      expect(markdown, contains('Total Reviews Analyzed:** 20'));
      expect(markdown, contains('Engineering & Product Action Item'));
      expect(markdown, contains('Beloved Features to Protect'));
    });
  });

  group('Scale to 240 and 333 Reviews (#525)', () {
    test('scales base review list to exact target counts (240 & 333)', () async {
      final belongJson = jsonDecode(
        await File('test/fixtures/belong_reviews_sample.json').readAsString(),
      );
      final baseReviews = parseBelongInAppFeedbackJson(belongJson);
      expect(baseReviews.length, equals(20));

      final scaled240 = scaleReviewsToCount(baseReviews, 240);
      expect(scaled240.length, equals(240));

      final report240 = ReviewSentimentReport(
        appId: 'com.belongonthespectrum.sanctuary',
        appName: 'Belong on the Spectrum',
        reviews: scaled240,
        targetPreset: ReviewTargetPreset.belong,
      );
      expect(report240.averageRating, closeTo(4.4, 0.05));
      expect(report240.generateMarkdown(), contains('Total Reviews Analyzed:** 240'));

      final scaled333 = scaleReviewsToCount(baseReviews, 333);
      expect(scaled333.length, equals(333));
      final report333 = ReviewSentimentReport(
        appId: 'com.belongonthespectrum.sanctuary',
        appName: 'Belong on the Spectrum',
        reviews: scaled333,
        targetPreset: ReviewTargetPreset.belong,
      );
      expect(report333.averageRating, closeTo(4.4, 0.05));
      expect(report333.generateMarkdown(), contains('Total Reviews Analyzed:** 333'));
    });
  });
}
