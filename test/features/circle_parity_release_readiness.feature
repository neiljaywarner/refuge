Feature: Belong on the Spectrum Circle.so Parity & Release Readiness
  As an autistic community member and disciple
  I want full community platform functionality matching Circle.so without cognitive overload
  So that I can connect, reflect, message, and attend fellowship peacefully

  # Driven via Marionette MCP, Maestro MCP, and patrolWidgetTest with patrol_finders ($)
  Scenario: Exploring Circle spaces, sections, and member directory
    Given the app is running on the Home screen
    Then I see "Belong"
    When I tap {#subnav_spaces_tab}
    Then I see "PINNED"
    And I see "General Chat"
    And I see "COMMUNITY"
    And I see "Members Section & Directory"
    When I tap "Members Section & Directory"
    Then I see "Member Directory"
    And I see "Fellowship disciples & leaders"

  Scenario: Switching between Direct Messages, Notifications, and Search
    Given the app is running on the Home screen
    When I tap {#bottom_nav_icon_notifications}
    Then I see "Notifications"
    And I see "All notifications are delivered gently without intrusive sound alerts."
    When I tap {#bottom_nav_icon_msgs}
    Then I see "Direct Messages"
    When I tap {#bottom_nav_icon_search}
    Then I see "Search"

  Scenario: Toggling sensory themes and high contrast mode
    Given the app is running on the Home screen
    When I tap {#appbar_contrast_toggle}
    Then I see "High Contrast Mode"
    When I tap {#appbar_sensory_themes_button}
    Then I see "Sensory Palettes"
