Feature: Feedback sheet clears the Android navigation bar
  The Vote on Features sheet should sit above the system navigation bar.
  The home bottom bar should keep a single gap, not two.

  Scenario: The feedback sheet clears the navigation bar
    Given the Android navigation bar is present
    And the sheet's own bottom padding is empty
    When a member opens Vote on Features
    Then the sheet sits above the navigation bar
    And the list inside the sheet keeps its own spacing

  Scenario: The feedback sheet is not padded twice
    Given the navigation bar is already counted once
    When a member opens Vote on Features
    Then the sheet adds that bar only once
    And the list inside the sheet keeps its own spacing

  Scenario: The keyboard replaces the navigation bar on the sheet
    Given the keyboard is open
    And the navigation bar is behind the keyboard
    When a member opens Vote on Features
    Then the sheet uses the keyboard space
    And it does not add the navigation bar on top of the keyboard

  Scenario: The home bottom bar is not padded twice
    Given the home screen has a bottom navigation bar
    And the system navigation bar is present
    When the page is shown
    Then the page body does not add a second gap
    And the bottom bar clears the system bar once
