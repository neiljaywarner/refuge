Feature: Timestamps beside posts and direct messages
  A member should see when a post or direct message was sent
  without typing the date into the words.

  Scenario: A post created on 20 Oct shows Oct 20 beside the author
    Given a post by David M. created on 20 Oct
    And the post body does not contain that date
    When the post card is shown
    Then the card shows "Oct 20" beside the author
    And the date is not inside the post body

  Scenario: A direct message sent on 20 Oct shows Oct 20 beside the message
    Given a direct message from Fellow Member sent on 20 Oct
    And the message text does not contain that date
    When the conversation is opened
    Then the message shows "Oct 20" beside the text
    And the date is not inside the message text
