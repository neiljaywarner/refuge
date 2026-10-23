import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:refuge4serverpod/src/features/branding/domain/community_brand_config.dart';
import 'package:refuge4serverpod/src/features/branding/presentation/brand_config_provider.dart';
import 'package:refuge4serverpod/src/features/profile/domain/member_profile.dart';

/// Immutable snapshot of community organizer settings controlled via
/// **Firebase Remote Config** (`docs/wiki/Organizer-Remote-Config-Guide.md`).
///
/// Works identically across **Flutter Web / PWA, Android, and iOS**, allowing
/// non-technical organizers at **Belong on the Spectrum** to update the
/// *"Message from the Organizer"* card, Community Guidelines, and app store
/// links without needing a developer or code deployment.
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
    this.previewModeEnabled = false,
    this.adminEmailsCsv = 'neilwarner@gmail.com',
  });

  factory OrganizerRemoteConfig.defaults(CommunityBrandConfig brand) => OrganizerRemoteConfig(
    welcomeTitle: brand.defaultOrganizerWelcomeTitle,
    welcomeMessage: brand.defaultOrganizerWelcomeMessage,
    bannerEnabled: true,
    dfwChurchUrl: brand.partnerOrgUrl,
    communityGuidelinesMarkdown: _defaultGuidelines,
    androidAppDownloadUrl: '',
    iosAppDownloadUrl: '',
    previewModeEnabled: false,
    adminEmailsCsv: 'neilwarner@gmail.com',
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
  final bool previewModeEnabled;
  final String adminEmailsCsv;

  /// Parsed list of administrator email addresses, normalized to lower case.
  List<String> get adminEmails => adminEmailsCsv
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  /// Returns true if [email] is present in the admin emails list.
  bool isAdminEmail(String? email) {
    if (email == null) return false;
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return adminEmails.contains(normalized);
  }

  OrganizerRemoteConfig copyWith({
    String? welcomeTitle,
    String? welcomeMessage,
    bool? bannerEnabled,
    String? dfwChurchUrl,
    String? communityGuidelinesMarkdown,
    String? androidAppDownloadUrl,
    String? iosAppDownloadUrl,
    bool? previewModeEnabled,
    String? adminEmailsCsv,
  }) => OrganizerRemoteConfig(
    welcomeTitle: welcomeTitle ?? this.welcomeTitle,
    welcomeMessage: welcomeMessage ?? this.welcomeMessage,
    bannerEnabled: bannerEnabled ?? this.bannerEnabled,
    dfwChurchUrl: dfwChurchUrl ?? this.dfwChurchUrl,
    communityGuidelinesMarkdown: communityGuidelinesMarkdown ?? this.communityGuidelinesMarkdown,
    androidAppDownloadUrl: androidAppDownloadUrl ?? this.androidAppDownloadUrl,
    iosAppDownloadUrl: iosAppDownloadUrl ?? this.iosAppDownloadUrl,
    previewModeEnabled: previewModeEnabled ?? this.previewModeEnabled,
    adminEmailsCsv: adminEmailsCsv ?? this.adminEmailsCsv,
  );
}

/// Service that reads live [FirebaseRemoteConfig] values when Firebase is
/// initialized for the active flavor (`dev` or `prod`) and gracefully falls
/// back to [OrganizerRemoteConfig.defaults] in unit/BDD tests or offline runs.
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
      final previewModeStr = rc.getString('organizer_preview_mode_enabled').trim();
      final adminEmailsStr = rc.getString('admin_emails_csv').trim();

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
        previewModeEnabled: previewModeStr.isEmpty
            ? defaults.previewModeEnabled
            : previewModeStr.toLowerCase() == 'true',
        adminEmailsCsv: adminEmailsStr.isNotEmpty
            ? adminEmailsStr
            : defaults.adminEmailsCsv,
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

/// Evaluates whether the currently signed-in user is recognized as an Admin
/// based on the Firebase Remote Config [adminEmailsCsv] list.
final isAdminProvider = Provider<bool>((ref) {
  final remoteConfig = ref.watch(organizerRemoteConfigProvider);
  final profile = ref.watch(memberProfileProvider);
  if (!profile.isSignedIn) return false;
  return remoteConfig.isAdminEmail(profile.email);
});