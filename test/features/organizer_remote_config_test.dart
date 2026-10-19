import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/main.dart';

void main() {
  group('BDD Feature: Flavors & Organizer Remote Config (#20)', () {
    test(
      'Scenario: Default OrganizerRemoteConfig falls back cleanly when Firebase is not initialized',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final config = container.read(organizerRemoteConfigProvider);
        expect(config.welcomeTitle, 'Welcome to Belong on the Spectrum');
        expect(config.bannerEnabled, isTrue);
        expect(config.dfwChurchUrl, 'https://dfwchurch.org');
        expect(
          config.communityGuidelinesMarkdown,
          contains('You Belong Here'),
        );
      },
    );

    test(
      'Scenario: Custom OrganizerRemoteConfig override updates welcome title and message',
      () {
        const brand = CommunityBrandConfig.belong();
        final customConfig = OrganizerRemoteConfig.defaults(brand).copyWith(
          welcomeTitle: 'Sunday Fellowship Update from the Organizer',
          welcomeMessage: 'Join us in General Chat at 4pm Central!',
        );

        final container = ProviderContainer(
          overrides: [
            organizerRemoteConfigProvider.overrideWithValue(customConfig),
          ],
        );
        addTearDown(container.dispose);

        final active = container.read(organizerRemoteConfigProvider);
        expect(
          active.welcomeTitle,
          'Sunday Fellowship Update from the Organizer',
        );
        expect(
          active.welcomeMessage,
          'Join us in General Chat at 4pm Central!',
        );
      },
    );

    test(
      'Scenario: CommunityAnalyticsService tags events with the active AppFlavor (dev vs prod)',
      () async {
        final devContainer = ProviderContainer(
          overrides: [appFlavorProvider.overrideWithValue(AppFlavor.dev)],
        );
        final prodContainer = ProviderContainer(
          overrides: [appFlavorProvider.overrideWithValue(AppFlavor.prod)],
        );
        addTearDown(devContainer.dispose);
        addTearDown(prodContainer.dispose);

        final devAnalytics = devContainer.read(
          communityAnalyticsServiceProvider,
        );
        final prodAnalytics = prodContainer.read(
          communityAnalyticsServiceProvider,
        );

        await devAnalytics.logSpaceViewed('general_chat');
        await prodAnalytics.logSpaceViewed('memes');

        expect(devAnalytics.recordedEventsForTesting.single['flavor'], 'dev');
        expect(
          devAnalytics.recordedEventsForTesting.single['space_slug'],
          'general_chat',
        );
        expect(prodAnalytics.recordedEventsForTesting.single['flavor'], 'prod');
        expect(
          prodAnalytics.recordedEventsForTesting.single['space_slug'],
          'memes',
        );
      },
    );
  });
}
