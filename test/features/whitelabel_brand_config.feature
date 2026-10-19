Feature: White-Label CommunityBrandConfig
  As a community organizer
  I want Refuge to load Belong on the Spectrum branding by default while allowing custom white-label tenant overrides
  So that belongonthespectrum.com has its authentic identity and future partner organizations can customize branding without code duplication

  Scenario: Default tenant is Belong on the Spectrum
    Given the default communityBrandConfigProvider
    Then the tenantId should be "belong"
    And the shortName should be "Belong"
    And the fullName should be "Belong on the Spectrum"
    And the partnerOrgUrl should be "https://dfwchurch.org"
    And the logoAssetPath should be "assets/images/belong_logo.png"

  Scenario: Custom white-label tenant override in ProviderScope
    Given a custom CommunityBrandConfig for "grace_spectrum"
    When a HookConsumerWidget reads communityBrandConfigProvider
    Then it renders the custom tenant shortName and tagline
