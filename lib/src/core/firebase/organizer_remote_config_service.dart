import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/branding/presentation/brand_config_provider.dart';

@immutable
class OrganizerRemoteConfig {
  const OrganizerRemoteConfig({
    required this.welcomeTitle,
    required this.welcomeMessage,
    required this.bannerEnabled,
    required this.dfwChurchUrl,
    required this.communityGuidelinesMarkdown,
    required this.androidAppDownloadUrl,
    required this.iosAppDownloadUrl,
  });

  factory OrganizerRemoteConfig.defaults(CommunityBrandConfig brand) => OrganizerRemoteConfig(
    welcomeTitle: brand.defaultOrganizerWelcomeTitle,
    welcomeMessage: brand.defaultOrganizerWelcomeMessage,
    bannerEnabled: true,
    dfwChurchUrl: brand.partnerOrgUrl,
    communityGuidelinesMarkdown: _defaultGuidelines,
    androidAppDownloadUrl: '',
    iosAppDownloadUrl: '',
  );

  static const String _defaultGuidelines = '''
# Belong on the Spectrum — Community Guidelines

1. **You Belong Here**: We celebrate neurodivergent and autistic communication styles. Literal questions, infodumping about special interests, and quiet lurking are all warmly welcomed.
2. **Kindness & Grace**: Treat every member, friend, and family member with Christ-like patience and empathy.
3. **Respect Sensory & Emotional Boundaries**: Honour post intent tags (such as *Comfort Only* vs *Seeking Advice*).
''';

  final String welcomeTitle;
  final String welcomeMessage;
  final bool bannerEnabled;
  final String dfwChurchUrl;
  final String communityGuidelinesMarkdown;
  final String androidAppDownloadUrl;
  final String iosAppDownloadUrl;

  OrganizerRemoteConfig copyWith({
    String? welcomeTitle,
    String? welcomeMessage,
    bool? bannerEnabled,
    String? dfwChurchUrl,
    String? communityGuidelinesMarkdown,
    String? androidAppDownloadUrl,
    String? iosAppDownloadUrl,
  }) => OrganizerRemoteConfig(
    welcomeTitle: welcomeTitle ?? this.welcomeTitle,
    welcomeMessage: welcomeMessage ?? this.welcomeMessage,
    bannerEnabled: bannerEnabled ?? this.bannerEnabled,
    dfwChurchUrl: dfwChurchUrl ?? this.dfwChurchUrl,
    communityGuidelinesMarkdown: communityGuidelinesMarkdown ?? this.communityGuidelinesMarkdown,
    androidAppDownloadUrl: androidAppDownloadUrl ?? this.androidAppDownloadUrl,
    iosAppDownloadUrl: iosAppDownloadUrl ?? this.iosAppDownloadUrl,
  );
}

class OrganizerRemoteConfigService {
  const OrganizerRemoteConfigService(this._brand);

  final CommunityBrandConfig _brand;

  OrganizerRemoteConfig readCurrent() {
    final defaults = OrganizerRemoteConfig.defaults(_brand);
    if (Firebase.apps.isEmpty) {
      return defaults;
    }
    try {
      final rc = FirebaseRemoteConfig.instance;
      final title = rc.getString('organizer_welcome_title').trim();
      final msg = rc.getString('organizer_welcome_message').trim();
      final dfw = rc.getString('dfw_church_url').trim();
      final guidelines = rc.getString('community_guidelines_markdown').trim();
      final androidUrl = rc.getString('android_app_download_url').trim();
      final iosUrl = rc.getString('ios_app_download_url').trim();
      final enabledStr = rc.getString('organizer_banner_enabled').trim();

      return OrganizerRemoteConfig(
        welcomeTitle: title.isNotEmpty ? title : defaults.welcomeTitle,
        welcomeMessage: msg.isNotEmpty ? msg : defaults.welcomeMessage,
        bannerEnabled: enabledStr.isEmpty
            ? defaults.bannerEnabled
            : enabledStr.toLowerCase() != 'false',
        dfwChurchUrl: dfw.isNotEmpty ? dfw : defaults.dfwChurchUrl,
        communityGuidelinesMarkdown: guidelines.isNotEmpty
            ? guidelines
            : defaults.communityGuidelinesMarkdown,
        androidAppDownloadUrl: androidUrl,
        iosAppDownloadUrl: iosUrl,
      );
    } catch (_) {
      return defaults;
    }
  }
}

final organizerRemoteConfigProvider = Provider<OrganizerRemoteConfig>((ref) {
  final brand = ref.watch(communityBrandConfigProvider);
  return OrganizerRemoteConfigService(brand).readCurrent();
});
