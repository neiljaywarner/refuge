import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/main.dart';
import 'package:refuge4serverpod/src/core/config/app_flavor.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';

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
        expect(
          config.welcomeMessage,
          contains('A quiet, safe fellowship space'),
        );
      },
    );

    test(
      'Scenario: Custom remote config values are parsed and exposed correctly',
      () {
        const customConfig = OrganizerRemoteConfig(
          welcomeTitle: 'Summer Fellowship Retreat',
          welcomeMessage: 'Join us tonight for quiet fellowship at 7pm CDT.',
          bannerEnabled: true,
          communityGuidelinesMarkdown:
              '# Guidelines\n1. Be kind.\n2. Respect sensory needs.',
        );

        final container = ProviderContainer(
          overrides: [
            organizerRemoteConfigProvider.overrideWithValue(customConfig),
          ],
        );
        addTearDown(container.dispose);

        final config = container.read(organizerRemoteConfigProvider);
        expect(config.welcomeTitle, 'Summer Fellowship Retreat');
        expect(
          config.welcomeMessage,
          'Join us tonight for quiet fellowship at 7pm CDT.',
        );
        expect(config.bannerEnabled, isTrue);
        expect(
          config.communityGuidelinesMarkdown,
          contains('Respect sensory needs.'),
        );
      },
    );

    test(
      'Scenario: CommunityAnalyticsService correctly separates Dev and Prod event payloads',
      () {
        final devAnalytics = CommunityAnalyticsService(flavor: 'dev');
        final prodAnalytics = CommunityAnalyticsService(flavor: 'prod');

        devAnalytics.logSpaceViewed('general_chat');
        prodAnalytics.logSpaceViewed('memes');

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

    test(
      'Scenario: AppFlavor resolves refuge applicationId suffixes and subdomain URL prefixes (#389, #472)',
      () {
        expect(AppFlavor.baseApplicationId, 'com.belongonthespectrum.refuge');

        expect(AppFlavor.dev.applicationIdSuffix, '.dev');
        expect(
          AppFlavor.dev.applicationId,
          'com.belongonthespectrum.refuge.dev',
        );
        expect(AppFlavor.dev.urlPrefix, 'dev.');
        expect(
          AppFlavor.dev.websiteUrl,
          'https://dev.belongonthespectrum.com/',
        );
        expect(
          AppFlavor.dev.firebaseHostingUrl,
          'https://dev-belongonthespectrum.web.app',
        );

        expect(AppFlavor.stg.applicationIdSuffix, '.stg');
        expect(
          AppFlavor.stg.applicationId,
          'com.belongonthespectrum.refuge.stg',
        );
        expect(
          AppFlavor.stg.websiteUrl,
          'https://stg.belongonthespectrum.com/',
        );

        expect(AppFlavor.qa.applicationIdSuffix, '.qa');
        expect(
          AppFlavor.qa.applicationId,
          'com.belongonthespectrum.refuge.qa',
        );
        expect(
          AppFlavor.qa.websiteUrl,
          'https://qa.belongonthespectrum.com/',
        );

        expect(AppFlavor.prod.applicationIdSuffix, '');
        expect(
          AppFlavor.prod.applicationId,
          'com.belongonthespectrum.refuge',
        );
        expect(AppFlavor.prod.urlPrefix, '');
        expect(
          AppFlavor.prod.websiteUrl,
          'https://www.belongonthespectrum.com/',
        );
        expect(
          AppFlavor.prod.firebaseHostingUrl,
          'https://belongonthespectrum.web.app',
        );

        expect(
          CommunityBrandConfig.forFlavor(AppFlavor.dev).websiteUrl,
          'https://dev.belongonthespectrum.com/',
        );
        expect(
          CommunityBrandConfig.forFlavor(AppFlavor.prod).websiteUrl,
          'https://www.belongonthespectrum.com/',
        );
      },
    );
  });
}
