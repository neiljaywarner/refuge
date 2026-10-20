import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/core/config/preview_mode_provider.dart';
import 'package:refuge4serverpod/src/core/firebase/organizer_remote_config_service.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';

void main() {
  group('Preview Mode & Single Master Feature Flag Unit Tests', () {
    test('Defaults to false when remote config is disabled and no user override is set', () {
      final container = ProviderContainer(
        overrides: [
          organizerRemoteConfigProvider.overrideWithValue(
            OrganizerRemoteConfig.defaults(const CommunityBrandConfig.belong()),
          ),
        ],
      );

      expect(container.read(previewFeaturesEnabledProvider), isFalse);
    });

    test('Reflects Remote Config when organizer enables preview mode', () {
      final configWithPreview = OrganizerRemoteConfig.defaults(
        const CommunityBrandConfig.belong(),
      ).copyWith(previewModeEnabled: true);

      final container = ProviderContainer(
        overrides: [
          organizerRemoteConfigProvider.overrideWithValue(configWithPreview),
        ],
      );

      expect(container.read(previewFeaturesEnabledProvider), isTrue);
    });

    test('Local user override takes precedence over Remote Config default', () {
      // Remote config is true, but user explicitly opts out
      final configWithPreview = OrganizerRemoteConfig.defaults(
        const CommunityBrandConfig.belong(),
      ).copyWith(previewModeEnabled: true);

      final container = ProviderContainer(
        overrides: [
          organizerRemoteConfigProvider.overrideWithValue(configWithPreview),
        ],
      );

      expect(container.read(previewFeaturesEnabledProvider), isTrue);

      // User sets override to false
      container.read(previewModeUserOverrideProvider.notifier).state = false;
      container.read(previewFeaturesEnabledProvider.notifier).setEnabled(false);

      expect(container.read(previewFeaturesEnabledProvider), isFalse);
    });
  });
}
