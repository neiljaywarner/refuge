Feature: Qualitative Care Affirmations Without Dopamine Loops
  As a fellowship member seeking prayer or emotional solace
  I want qualitative care reactions (Praying, Standing With, Peace, Encouraged)
  So that I feel supported without the vanity metrics or popularity contests of social media

  Scenario: Incrementing qualitative care affirmations
    Given the Sanctuary application is open
    Then I should see the initial count "6 Praying" on David's reflection
    When I tap the "6 Praying" affirmation button
    Then the counter should atomically increment to "7 Praying"
    And "6 Praying" should no longer be shown

  Scenario: Publishing an unhurried reflection
    Given the Sanctuary application is open
    When I type "Grateful for still waters and quiet minds." into the reflection composer
    And I tap "Publish Reflection"
    Then the new reflection should appear at the top of the feed
    And the reflection input field should be cleanly cleared
