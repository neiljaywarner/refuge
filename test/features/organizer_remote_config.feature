Feature: Multi-Environment Flavors and Firebase Remote Config ("Message from the Organizer")
  As a non-technical community organizer at Belong on the Spectrum
  I want to update the "Message from the Organizer" welcome banner via Firebase Remote Config while keeping dev and prod flavors strictly isolated
  So that I can publish community announcements anytime without developer code changes or test data pollution

  Scenario: Default OrganizerRemoteConfig falls back cleanly when Firebase is not initialized
    Given the default organizerRemoteConfigProvider
    Then welcomeTitle should be "Welcome to Belong on the Spectrum"
    And bannerEnabled should be true
    And dfwChurchUrl should be "https://dfwchurch.org"

  Scenario: Custom OrganizerRemoteConfig override updates welcome title and message
    Given a custom OrganizerRemoteConfig from the community organizer
    Then the provider exposes the updated organizer message

  Scenario: CommunityAnalyticsService tags events with the active AppFlavor (dev vs prod)
    Given a CommunityAnalyticsService for AppFlavor.dev and AppFlavor.prod
    When logSpaceViewed is called for "general_chat"
    Then the recorded event includes the exact flavor slug ("dev" vs "prod")
