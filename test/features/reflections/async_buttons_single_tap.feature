Feature: Buttons that save something show a spinner and ignore repeat taps (#977)
  On a slow phone connection, a second tap must not post or toggle twice.

  Scenario: Publishing a reflection twice in a row posts it once
    Given the reflection composer with a slow connection
    When I write a reflection and tap Publish twice
    Then Publish shows a spinner
    And the reflection is submitted once

  Scenario: Tapping Save for Later twice in a row saves it once
    Given a reflection card with a slow connection
    When I tap Save for Later twice
    Then the save button shows a spinner
    And the post is toggled once

  Scenario: Collapsing and expanding mid-publish does not submit twice
    Given the feed composer with a slow connection
    When I write a reflection, tap Publish, collapse, expand, and tap Publish again
    Then the reflection is submitted once
    And Publish shows a spinner

