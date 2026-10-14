Feature: Fellowship Spaces and Mindful Intent Navigation
  As a neurodivergent fellowship member
  I want peaceful, unhurried fellowship rooms
  So that I can receive encouragement and prayer without sensory overload or notifications

  Scenario: Switching between fellowship spaces displays space-specific reflections
    Given the Sanctuary application is open in the default "#prayer-sanctuary" room
    Then I should see reflections from "David M. (UK)"
    And I should not see reflections from "Pastor Thomas (Melbourne)"
    When I tap on the "📖 #weekly-study" space chip
    Then I should see reflections from "Pastor Thomas (Melbourne)"
    And I should not see reflections from "David M. (UK)"

  Scenario: Visiting an empty fellowship room shows peaceful stillness
    Given the Sanctuary application is open
    When I tap on the "📢 #announcements" space chip
    Then I should see "Space is quiet right now"
    And I should not see any chaotic error banners

  Scenario: Filtering reflections by mindful intent tags
    Given the Sanctuary application is open in the "#prayer-sanctuary" room
    When I select the "[Comfort Only]" intent filter chip
    Then I should see reflections from "Elena R. (Colorado)"
    And I should not see reflections from "David M. (UK)"
    When I select the "All" intent filter chip
    Then I should see reflections from both "David M. (UK)" and "Elena R. (Colorado)"
