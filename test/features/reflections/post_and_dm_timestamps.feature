Feature: Timestamps beside posts and direct messages
  A member should see when a post or direct message was sent
  without typing the date into the body.

  Scenario: A post shows its own timestamp beside the content
    Given a post by David M. was created on a known date
    And the post body does not contain that date
    Then the formatted timestamp is visible beside the post

  Scenario: A direct message shows its own timestamp beside the content
    Given a direct message from Fellow Member was sent on a known date
    And the message body does not contain that date
    Then the formatted timestamp is visible beside the message
