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
    required this.sageAccentColor,
    required this.warmAmberAccentColor,
    required this.defaultSubredditOrSpaceTag,
    required this.defaultCategoryLabel,
    required this.sensoryDisclaimerMarkdown,
    required this.fellowshipAffiliationPrompt,
    required this.fellowshipAffiliationOptions,
    required this.fellowshipNonMemberOption,
  });

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
      sensoryDisclaimerMarkdown =
          'Belong is intentionally designed with subdued sensory stimulation, low-glare palettes, and zero unrequested autoplay audio or video.',
      fellowshipAffiliationPrompt = 'Which ICOC church do you attend?',
      fellowshipAffiliationOptions = const [
        'DFW Church (Partner)',
        'Austin Christian Church',
        'Boston Church of Christ',
        'Greater Long Beach Church',
        'Other ICOC Congregation',
      ],
      fellowshipNonMemberOption = 'I am not a member of an ICOC church';

  /// Flavor-aware flagship configuration for **Belong on the Spectrum**
  /// (`https://dev.belongonthespectrum.com/` in `dev`, `https://www.belongonthespectrum.com/` in `prod`).
  factory CommunityBrandConfig.forFlavor(AppFlavor flavor) {
    return const CommunityBrandConfig.belong().copyWith(
      websiteUrl: flavor.websiteUrl,
    );
  }

  /// Resolves the canonical website URL for the given [flavor], preserving custom
  /// white-label tenant URLs while applying flavor prefixes (`dev.`, `stg.`, `qa.`)
  /// for the flagship Belong tenant.
  String websiteUrlForFlavor(AppFlavor flavor) {
    if (tenantId == 'belong' &&
        websiteUrl == 'https://www.belongonthespectrum.com/') {
      return flavor.websiteUrl;
    }
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
  final String defaultSubredditOrSpaceTag;
  final String defaultCategoryLabel;
  final String sensoryDisclaimerMarkdown;
  final String fellowshipAffiliationPrompt;
  final List<String> fellowshipAffiliationOptions;
  final String fellowshipNonMemberOption;

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
    String? defaultSubredditOrSpaceTag,
    String? defaultCategoryLabel,
    String? sensoryDisclaimerMarkdown,
    String? fellowshipAffiliationPrompt,
    List<String>? fellowshipAffiliationOptions,
    String? fellowshipNonMemberOption,
  }) {
    return CommunityBrandConfig(
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
      warmAmberAccentColor: warmAmberAccentColor ?? this.warmAmberAccentColor,
      defaultSubredditOrSpaceTag:
          defaultSubredditOrSpaceTag ?? this.defaultSubredditOrSpaceTag,
      defaultCategoryLabel: defaultCategoryLabel ?? this.defaultCategoryLabel,
      sensoryDisclaimerMarkdown:
          sensoryDisclaimerMarkdown ?? this.sensoryDisclaimerMarkdown,
      fellowshipAffiliationPrompt:
          fellowshipAffiliationPrompt ?? this.fellowshipAffiliationPrompt,
      fellowshipAffiliationOptions:
          fellowshipAffiliationOptions ?? this.fellowshipAffiliationOptions,
      fellowshipNonMemberOption:
          fellowshipNonMemberOption ?? this.fellowshipNonMemberOption,
    );
  }
}
