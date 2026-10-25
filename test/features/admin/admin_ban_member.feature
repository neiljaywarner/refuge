Feature: Admin ban quarantine
  As a signed-in community admin
  I want a confirmed ban to pause that member
  So that fellowship posting stays calm until I restore them

  Scenario: Cancel writes nothing
    Given an admin is viewing Caleb Stone
    When the admin opens Ban Member and taps Cancel
    Then Caleb Stone is not banned

  Scenario: A failed ban shows the error snackbar
    Given an admin is viewing Caleb Stone
    When the ban repository fails
    Then the member stays unbanned and an error snackbar is shown

  Scenario: Ban hides the directory card and pauses posting
    Given an admin bans Caleb Stone from the directory
    Then the directory no longer lists Caleb Stone
    And a session named Caleb Stone cannot sign in or read the feed
    And that session cannot create a post
    And Caleb Stone's posts, comments, and messages are removed

  Scenario: A ban is not undone from the app
    Given Caleb Stone was banned
    Then the directory does not list Caleb Stone
    And the app does not offer Restore
    And Caleb Stone's posts stay removed
