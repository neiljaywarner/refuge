Feature: Group call microphone and audio

  Readable scenarios for the preview call microphone (#909).
  bdd_widget_test is not a package in this repo, same as
  direct_message_alerts.feature. The steps in step/ are the
  executable definitions, and group_call_mic_bdd_test.dart runs them.

  Scenario: A muted join publishes audio on the first unmute
    Given the call joined with the microphone off
    When the member unmutes
    Then the microphone icon is on
    And the first microphone request publishes audio

  Scenario: Three mute and unmute cycles keep the track alive
    Given the microphone is already sending
    When the member completes three mute and unmute cycles
    Then every mute kept the track alive

  Scenario: An external mute updates the icon
    Given the member has unmuted
    When the call mutes the microphone from outside
    Then the microphone icon is off
    And the next tap unmutes

  Scenario: A failed microphone change leaves the icon
    Given the member has unmuted
    When the next microphone change fails
    Then the microphone icon is on
    And the calm microphone snackbar is shown

  Scenario: A guest without send-audio sees the snackbar
    Given a guest joined without send-audio
    When the member unmutes
    Then the microphone icon is off
    And the calm microphone snackbar is shown

  Scenario: Web autoplay offers a tap to hear the room
    Given the browser is blocking remote audio
    Then the call shows Tap to hear the room
    When the member taps to hear the room
    Then resumeWebAudioPlayback is called

  Scenario: The speaker is on by default
    Given a preview join plan
    Then the speaker starts on

  Scenario: The camera still toggles beside the microphone
    Given the call joined with the microphone off
    When the member turns the camera on
    And the member unmutes
    Then the camera icon is on
    And the microphone icon is on

  Scenario: A guest does not see host controls
    Given a guest is in the call
    Then remove and end are hidden

  Scenario: A host sees host controls
    Given a host created the call
    Then remove and end are shown
