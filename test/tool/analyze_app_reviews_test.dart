import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Since tool/analyze_app_reviews.dart is a CLI script, we can test its models and parsing logic.
// We import via relative path to the tool script.
import '../../tool/analyze_app_reviews.dart';

void main() {
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

      expect(reviews.length, equals(5));

      final first = reviews.first;
      expect(first.id, equals('rev-001'));
      expect(first.rating, equals(1));
      expect(first.title, contains('Notification spam'));
      expect(first.version, equals('3.12.0'));
      expect(first.isNegative, isTrue);

      final last = reviews.last;
      expect(last.id, equals('rev-005'));
      expect(last.rating, equals(5));
      expect(last.title, contains('Best community platform'));
      expect(last.isPositive, isTrue);
    });

    test('calculates correct rating distributions and taxonomy buckets', () async {
      final sampleFile = File('test/fixtures/apple_reviews_sample.json');
      final jsonContent = jsonDecode(await sampleFile.readAsString()) as Map<String, dynamic>;
      final reviews = parseAppleCustomerReviewsJson(jsonContent);

      final report = ReviewSentimentReport(
        appId: '1506475653',
        appName: 'Circle Communities',
        reviews: reviews,
      );

      expect(report.totalCount, equals(5));
      expect(report.countForRating(1), equals(1));
      expect(report.countForRating(2), equals(2));
      expect(report.countForRating(3), equals(0));
      expect(report.countForRating(4), equals(1));
      expect(report.countForRating(5), equals(1));
      expect(report.averageRating, closeTo(2.8, 0.01));

      final categories = report.categorizeByTopic();
      expect(categories['Notification Overload & Alerts']!.length, greaterThanOrEqualTo(1));
      expect(categories['Video & Media Playback']!.length, greaterThanOrEqualTo(1));
      expect(categories['Spaces, Community & Fellowship']!.length, greaterThanOrEqualTo(1));

      final markdown = report.generateMarkdown();
      expect(markdown, contains('# 📈 Mobile App Review Sentiment Report: Circle Communities'));
      expect(markdown, contains('Notifications & Alerts'));
      expect(markdown, contains('Mistakes to Avoid'));
      expect(markdown, contains('Beloved Patterns to Replicate'));
    });
  });
}
