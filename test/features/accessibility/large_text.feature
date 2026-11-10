Feature: Large system text stays usable

  People who set a large system font still need Belong to be usable:
  no clipped text, no hidden controls, calls still reachable.

  bdd_widget_test is not a package in this repo (#926). The steps in
  step/ are the executable definitions, and large_text_bdd_test.dart
  runs them. Each scenario below is checked at text scales 1.0, 1.3,
  2.0, and 3.0.

  Group call screens are not in this tree. They are on unmerged PR #905
  (branch cursor/stream-guest-join-2e7c). The call scenario is not
  executed until that UI is on main.

  Scenario: The sign-in wall stays on screen
    Given the sign-in wall is shown at large text scales
    Then the sign-in title is visible
    And the forgot-password control is tappable
    And no text overflow is reported

  Scenario: The home feed and bottom nav stay usable
    Given the home feed is shown at large text scales
    Then Belong and the Home tab are visible
    And the Home tab is tappable
    And no text overflow is reported

  Scenario: A reflection and its discussion stay usable
    Given a reflection card is shown at large text scales
    And the discussion is open at large text scales
    Then the discussion title is visible
    And no text overflow is reported

  Scenario: Direct messages stay usable
    Given a direct message thread is open at large text scales
    Then the message title is visible
    And no text overflow is reported

  Scenario: Sensory and notification settings stay usable
    Given sensory settings are open at large text scales
    And notification settings are open at large text scales
    Then the font scaling choices are visible
    And no text overflow is reported

  Scenario: The feedback sheet stays usable
    Given the feedback sheet is open at large text scales
    Then the feedback title is visible
    And no text overflow is reported

  # Follow-up after PR #905 merges. Do not treat this as covered.
  # Scenario: A guest can still join a call at text scale 2.0
  #   Given the guest join form is shown at text scale 2.0
  #   Then the join control is visible
  #   And no text overflow is reported
