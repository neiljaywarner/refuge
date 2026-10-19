import 'package:flutter/material.dart';

/// Immutable multi-tenant branding configuration allowing Refuge to power
/// **Belong on the Spectrum** (`belongonthespectrum.com`) as its flagship
/// community while remaining 100% white-labelable for partner churches and
/// neurodivergent-affirming organizations.
@immutable
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
    required this.warmGoldAccentColor,
    required this.defaultOrganizerWelcomeTitle,
    required this.defaultOrganizerWelcomeMessage,
  });

  /// Default flagship configuration for **Belong on the Spectrum**
  /// (`https://www.belongonthespectrum.com/`).
  const CommunityBrandConfig.belong()
    : tenantId = 'belong',
      shortName = 'Belong',
      fullName = 'Belong on the Spectrum',
      tagline =
          'You belong here — a calm, neurodivergent-affirming Christian & autistic fellowship community.',
      scriptureAnchor = 'Fearfully & Wonderfully Made (Psalm 139:14)',
      websiteUrl = 'https://www.belongonthespectrum.com/',
      partnerOrgName = 'DFW Church',
      partnerOrgUrl = 'https://dfwchurch.org',
      logoAssetPath = 'assets/images/belong_logo.png',
      creamBackgroundColor = const Color(0xFFF3EFE6),
      deepNavyPrimaryColor = const Color(0xFF112334),
      warmGoldAccentColor = const Color(0xFFC99F49),
      defaultOrganizerWelcomeTitle = 'Welcome to Belong on the Spectrum',
      defaultOrganizerWelcomeMessage =
          'You belong here. Take your time, choose a sensory theme that feels comfortable, and introduce yourself in Start Here when you are ready.';

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
  final Color warmGoldAccentColor;
  final String defaultOrganizerWelcomeTitle;
  final String defaultOrganizerWelcomeMessage;

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
    Color? warmGoldAccentColor,
    String? defaultOrganizerWelcomeTitle,
    String? defaultOrganizerWelcomeMessage,
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
      warmGoldAccentColor: warmGoldAccentColor ?? this.warmGoldAccentColor,
      defaultOrganizerWelcomeTitle:
          defaultOrganizerWelcomeTitle ?? this.defaultOrganizerWelcomeTitle,
      defaultOrganizerWelcomeMessage:
          defaultOrganizerWelcomeMessage ?? this.defaultOrganizerWelcomeMessage,
    );
  }
}
