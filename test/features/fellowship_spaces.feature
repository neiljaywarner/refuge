Feature: Fellowship Spaces and Mindful Intent Navigation
  As a neurodivergent fellowship member
  I want peaceful, unhurried fellowship spaces
  So that I can receive encouragement and prayer without sensory overload or notifications

  Scenario: Switching between fellowship spaces displays space-specific reflections
    Given the Refuge application is open in the Prayer Sanctuary space
    Then I should see reflections from "David M. (UK)"
    And I should not see reflections from "Pastor Thomas (Melbourne)"
    When I tap on the "📖 Weekly Study" space
    Then I should see reflections from "Pastor Thomas (Melbourne)"
    And I should not see reflections from "David M. (UK)"

  Scenario: Visiting Announcements shows that space's update
    Given the Refuge application is open
    When I tap on the "📢 Announcements" space
    Then I should see the Belong Leadership announcement
    And I should not see any chaotic error banners

  Scenario: Filtering reflections by mindful intent tags
    Given the Refuge application is open in the Prayer Sanctuary space
    When I select the "[Comfort Only]" intent filter chip
    Then I should see reflections from "Elena R. (Colorado)"
    And I should not see reflections from "David M. (UK)"
    When I select the "All" intent filter chip
    Then I should see reflections from both "David M. (UK)" and "Elena R. (Colorado)"
