Feature: Quiet message alerts

  Scenario: A member turns alerts on in Settings
    Given message alerts are off
    When the member turns Message alerts on
    Then a new direct message can arrive as a silent card

  Scenario: Alerts stay off until the member asks
    Given message alerts are off
    When someone sends a direct message
    Then no push is sent
