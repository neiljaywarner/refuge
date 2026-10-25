import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('CodeWithAndrea Riverpod Architecture & Provider Unit Tests', () {
    late ProviderContainer container;
    late LocalPostRepository repository;

    setUp(() {
      repository = LocalPostRepository();
      container = ProviderContainer(
        overrides: [postRepositoryProvider.overrideWithValue(repository)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('SensoryThemeNotifier initializes to Sage and updates mode immutably', () {
      expect(container.read(sensoryThemeModeProvider), SensoryMode.sage);

      container.read(sensoryThemeModeProvider.notifier).setMode(SensoryMode.charcoal);
      expect(container.read(sensoryThemeModeProvider), SensoryMode.charcoal);

      container.read(sensoryThemeModeProvider.notifier).setMode(SensoryMode.contrast);
      expect(container.read(sensoryThemeModeProvider), SensoryMode.contrast);

      container.read(sensoryThemeModeProvider.notifier).setMode(SensoryMode.clean);
      expect(container.read(sensoryThemeModeProvider), SensoryMode.clean);
    });

    test('activeSpaceKeyProvider tracks active fellowship room selection', () {
      expect(container.read(activeSpaceKeyProvider), 'prayer');

      container.read(activeSpaceKeyProvider.notifier).state = 'special_interests';
      expect(container.read(activeSpaceKeyProvider), 'special_interests');
    });

    test('postsStreamProvider streams space-specific posts reactively', () async {
      final postsAsync = await container.read(postsStreamProvider('prayer').future);
      expect(postsAsync.isNotEmpty, isTrue);
      expect(postsAsync.every((p) => p.spaceKey == 'prayer'), isTrue);
    });

    test('currentSpacePostsProvider combines space stream with active intent filter', () async {
      // Set space to prayer
      container.read(activeSpaceKeyProvider.notifier).state = 'prayer';

      // Await stream initialization
      await container.read(postsStreamProvider('prayer').future);

      // Set filter to [Comfort Only]
      container.read(activeFilterProvider.notifier).state = '[Comfort Only]';

      // Read currentSpacePostsProvider
      final postsAsync = container.read(currentSpacePostsProvider);
      expect(postsAsync.hasValue, isTrue);

      final filtered = postsAsync.value!;
      expect(filtered.length, 1);
      expect(filtered.first.authorName, 'Elena R. (Colorado)');
      expect(filtered.first.toneTag, '[Comfort Only]');
    });

    test('quietDigestProvider computes server-style calm summary for space', () async {
      final digest = await container.read(quietDigestProvider('prayer').future);
      expect(digest, isNotNull);
      expect(digest, contains('Gathered in peace'));
    });
  });
}
