import 'package:flutter/material.dart';

import '../../../core/config/app_flavor.dart';

/// Immutable multi-tenant branding configuration allowing Refuge to power
/// **Belong on the Spectrum** (`belongonthespectrum.com`) as its flagship
/// community while remaining 100% white-labelable for partner churches and
/// fellowship organizations (ADR-0003, #430, #433).
class CommunityBrandConfig {
  const CommunityBrandConfig({
    required this.tenantId,
    required this.shortName,
    required this.fullName,
    required this.tagline,
    required this.scriptureAnchor,
    required this.websiteUrl,
    required this.partnerOrgName,
    required this.partnerOrgUrl,
    required this.logoAssetPath,
    required this.creamBackgroundColor,
    required this.deepNavyPrimaryColor,
    Color? sageAccentColor,
    Color? warmAmberAccentColor,
    Color? warmGoldAccentColor,
    this.defaultSubredditOrSpaceTag = 'autistic_fellowship',
    this.defaultCategoryLabel = 'Spaces',
    this.sensoryDisclaimerMarkdown = 'Belong is intentionally designed with subdued sensory stimulation, low-glare palettes, and zero unrequested autoplay audio or video.',
    this.fellowshipAffiliationPrompt = 'Which ICOC church do you attend?',
    this.fellowshipAffiliationOptions = const [
      'DFW Church (Partner)',
      'Austin Christian Church',
      'Boston Church of Christ',
      'Greater Long Beach Church',
      'Other ICOC Congregation',
    ],
    this.fellowshipNonMemberOption = 'I am not a member of an ICOC church',
    this.defaultOrganizerWelcomeTitle = 'Welcome to Belong on the Spectrum',
    this.defaultOrganizerWelcomeMessage = 'A peaceful sanctuary for autistic Christians, families, and friends to connect at their own pace.',
    this.enableFellowshipAffiliationField = true,
  }) : sageAccentColor = sageAccentColor ?? const Color(0xFF68A67D),
       warmAmberAccentColor =
           warmGoldAccentColor ?? warmAmberAccentColor ?? const Color(0xFFD49137);

  /// Default flagship configuration for **Belong on the Spectrum**.
  const CommunityBrandConfig.belong()
    : tenantId = 'belong',
      shortName = 'Belong',
      fullName = 'Belong on the Spectrum',
      tagline = 'A peaceful autistic Christian fellowship community',
      scriptureAnchor = '1 Corinthians 12:22 · Romans 15:7',
      websiteUrl = 'https://www.belongonthespectrum.com/',
      partnerOrgName = 'International Churches of Christ (ICOC)',
      partnerOrgUrl = 'https://disciplestoday.org',
      logoAssetPath = 'assets/images/belong_logo.png',
      creamBackgroundColor = const Color(0xFFF7F5F0),
      deepNavyPrimaryColor = const Color(0xFF1B2A4A),
      sageAccentColor = const Color(0xFF68A67D),
      warmAmberAccentColor = const Color(0xFFD49137),
      defaultSubredditOrSpaceTag = 'autistic_fellowship',
      defaultCategoryLabel = 'Spaces',
      sensoryDisclaimerMarkdown = 'Belong is intentionally designed with subdued sensory stimulation, low-glare palettes, and zero unrequested autoplay audio or video.',
      fellowshipAffiliationPrompt = 'Which ICOC church do you attend?',
      fellowshipAffiliationOptions = const [
        'DFW Church (Partner)',
        'Austin Christian Church',
        'Boston Church of Christ',
        'Greater Long Beach Church',
        'Other ICOC Congregation',
      ],
      fellowshipNonMemberOption = 'I am not a member of an ICOC church',
      defaultOrganizerWelcomeTitle = 'Welcome to Belong on the Spectrum',
      defaultOrganizerWelcomeMessage = 'A peaceful sanctuary for autistic Christians, families, and friends to connect at their own pace.',
      enableFellowshipAffiliationField = true;

  /// Flavor-aware flagship configuration for **Belong on the Spectrum**.
  /// Uses Firebase Hosting web app URLs (`https://dev-belongonthespectrum.web.app/`
  /// in `dev`, `https://belongonthespectrum.web.app/` in `prod`). The marketing
  /// site at [AppFlavor.marketingWebsiteUrl] stays separate.
  factory CommunityBrandConfig.forFlavor(AppFlavor flavor) =>
      const CommunityBrandConfig.belong().copyWith(websiteUrl: flavor.websiteUrl);

  /// Resolves the canonical web app URL for the given [flavor], preserving custom
  /// white-label tenant URLs while mapping the flagship Belong marketing or
  /// hosting origins onto the active flavor's Firebase Hosting URL.
  String websiteUrlForFlavor(AppFlavor flavor) {
    if (tenantId != 'belong') return websiteUrl;
    final recognized = <String>{
      AppFlavor.marketingWebsiteUrl,
      for (final known in AppFlavor.values) known.websiteUrl,
    };
    if (recognized.contains(websiteUrl)) return flavor.websiteUrl;
    return websiteUrl;
  }

  final String tenantId;
  final String shortName;
  final String fullName;
  final String tagline;
  final String scriptureAnchor;
  final String websiteUrl;
  final String partnerOrgName;
  final String partnerOrgUrl;
  final String logoAssetPath;
  final Color creamBackgroundColor;
  final Color deepNavyPrimaryColor;
  final Color sageAccentColor;
  final Color warmAmberAccentColor;

  /// Backwards-compatibility alias for [warmAmberAccentColor].
  Color get warmGoldAccentColor => warmAmberAccentColor;
  final String defaultSubredditOrSpaceTag;
  final String defaultCategoryLabel;
  final String sensoryDisclaimerMarkdown;
  final String fellowshipAffiliationPrompt;
  final List<String> fellowshipAffiliationOptions;
  final String fellowshipNonMemberOption;
  final String defaultOrganizerWelcomeTitle;
  final String defaultOrganizerWelcomeMessage;
  final bool enableFellowshipAffiliationField;

  CommunityBrandConfig copyWith({
    String? tenantId,
    String? shortName,
    String? fullName,
    String? tagline,
    String? scriptureAnchor,
    String? websiteUrl,
    String? partnerOrgName,
    String? partnerOrgUrl,
    String? logoAssetPath,
    Color? creamBackgroundColor,
    Color? deepNavyPrimaryColor,
    Color? sageAccentColor,
    Color? warmAmberAccentColor,
    Color? warmGoldAccentColor,
    String? defaultSubredditOrSpaceTag,
    String? defaultCategoryLabel,
    String? sensoryDisclaimerMarkdown,
    String? fellowshipAffiliationPrompt,
    List<String>? fellowshipAffiliationOptions,
    String? fellowshipNonMemberOption,
    String? defaultOrganizerWelcomeTitle,
    String? defaultOrganizerWelcomeMessage,
    bool? enableFellowshipAffiliationField,
  }) => CommunityBrandConfig(
    tenantId: tenantId ?? this.tenantId,
    shortName: shortName ?? this.shortName,
    fullName: fullName ?? this.fullName,
    tagline: tagline ?? this.tagline,
    scriptureAnchor: scriptureAnchor ?? this.scriptureAnchor,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    partnerOrgName: partnerOrgName ?? this.partnerOrgName,
    partnerOrgUrl: partnerOrgUrl ?? this.partnerOrgUrl,
    logoAssetPath: logoAssetPath ?? this.logoAssetPath,
    creamBackgroundColor: creamBackgroundColor ?? this.creamBackgroundColor,
    deepNavyPrimaryColor: deepNavyPrimaryColor ?? this.deepNavyPrimaryColor,
    sageAccentColor: sageAccentColor ?? this.sageAccentColor,
    warmAmberAccentColor: warmGoldAccentColor ?? warmAmberAccentColor ?? this.warmAmberAccentColor,
    defaultSubredditOrSpaceTag: defaultSubredditOrSpaceTag ?? this.defaultSubredditOrSpaceTag,
    defaultCategoryLabel: defaultCategoryLabel ?? this.defaultCategoryLabel,
    sensoryDisclaimerMarkdown: sensoryDisclaimerMarkdown ?? this.sensoryDisclaimerMarkdown,
    fellowshipAffiliationPrompt: fellowshipAffiliationPrompt ?? this.fellowshipAffiliationPrompt,
    fellowshipAffiliationOptions: fellowshipAffiliationOptions ?? this.fellowshipAffiliationOptions,
    fellowshipNonMemberOption: fellowshipNonMemberOption ?? this.fellowshipNonMemberOption,
    defaultOrganizerWelcomeTitle: defaultOrganizerWelcomeTitle ?? this.defaultOrganizerWelcomeTitle,
    defaultOrganizerWelcomeMessage:
        defaultOrganizerWelcomeMessage ?? this.defaultOrganizerWelcomeMessage,
    enableFellowshipAffiliationField:
        enableFellowshipAffiliationField ?? this.enableFellowshipAffiliationField,
  );
}
