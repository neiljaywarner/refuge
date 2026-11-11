Feature: Group call screen share

  Readable scenarios for preview screen share (#928).
  bdd_widget_test is not a package in this repo, same as
  group_call_mic.feature. The steps in step/ are the executable
  definitions, and group_call_screen_share_bdd_test.dart runs them.

  Scenario: A guest cannot share
    Given a guest joined with screenshare granted
    Then the share button is hidden

  Scenario: The organizer allows a guest to share
    Given a guest joined with screenshare granted
    And the organizer has allowed guests to share
    When the guest starts sharing
    Then the share button shows stop
    And the presenter label says You are sharing

  Scenario: A member without screenshare cannot share
    Given a member joined without screenshare
    Then the share button is hidden

  Scenario: Stopping a share returns the grid
    Given a member is sharing on the web
    When the member stops sharing
    Then the presenter label is gone
    And the grid is showing

  Scenario: Someone else sharing is the main tile
    Given a remote person is sharing
    Then the presenter label names Alex
    And the share tile is showing

  Scenario: A host can let guests share
    Given a host joined with screenshare
    Then the host sees Let guests share
    When the host allows guests to share
    Then the call records that guests may share
