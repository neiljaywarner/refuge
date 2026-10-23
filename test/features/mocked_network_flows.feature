Feature: Community flows with a mocked network
  Members can vote, send feedback, read the bell, message someone, and publish
  text or image posts while HTTP, Firebase, and Serverpod stay mocked.

  Scenario: Member shares public praise
    Given the roadmap sheet is open against a mocked voting repository
    When the member sends a five-star praise note
    Then a thank-you is shown and the repository records the note

  Scenario: Member publishes a reflection and an image post
    Given the home feed uses a mocked post repository
    When the member publishes a text reflection and an image post
    Then both posts are stored without a live backend

  Scenario: Member clears one notification and sends a direct message
    Given the bell shows unread notifications
    When the member marks one notification read and sends a direct message
    Then that unread dot clears and the new thread opens
