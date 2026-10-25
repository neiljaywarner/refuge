Feature: Message alerts

  The in-app switch is Belong's on and off. The system screen named below
  is where sound and banners are changed. These scenarios are exercised by
  notification_preferences_test.dart, notification_settings_help_test.dart,
  and present_incoming_push_test.dart. bdd_widget_test is not a dependency,
  so this file is the readable specification rather than generated code.

  Scenario: A member turns alerts on in Settings
    Given message alerts are off
    When the member turns Message alerts on
    Then a new direct message shows as a notification, with sound
    And the sheet tells them where the system notification options are

  Scenario: Alerts stay off until the member asks
    Given message alerts are off
    When someone sends a direct message
    Then no push is sent

  Scenario: Immediate Gentle Cards stays quiet
    Given message alerts are on and the schedule is Immediate Gentle Cards
    When a direct message arrives
    Then the phone shows the quiet digest and does not play a sound
