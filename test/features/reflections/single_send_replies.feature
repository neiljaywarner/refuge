Feature: One tap on Send posts one reply (#977)
  On a slow phone connection the reply takes a moment to save.
  Tapping Send again during that moment must not post the reply twice.

  Scenario: Tapping Send twice while the first reply is still saving posts one reply
    Given a reflection with no replies
    And saving a reply is slow
    When I write "Holding you in prayer tonight." and tap Send
    And I tap Send again before the first reply has saved
    Then only one reply is saved
    And "Holding you in prayer tonight." appears once in the thread

  Scenario: The composer clears as soon as Send is tapped
    Given a reflection with no replies
    And saving a reply is slow
    When I write "Holding you in prayer tonight." and tap Send
    Then the reply box is empty
    And Send is disabled until the reply has saved

  Scenario: A second, separate reply still posts after the first has saved
    Given a reflection with one saved reply
    When I write "And for rest tomorrow." and tap Send
    Then two different replies are saved
