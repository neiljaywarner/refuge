Feature: WCAG Sensory Modes and Accessibility
  As a believer with light sensitivity or ADHD
  I want 4 calm-tech sensory modes
  So that I can read and fellowship without migraines or eye strain

  Scenario: Toggling through all 4 sensory themes
    Given the Sanctuary application is open
    When I tap on the "Dark" sensory button
    Then the theme should apply Monastic Dark charcoal tones
    When I tap on the "Contrast" sensory button
    Then the theme should apply High Contrast black-and-yellow tones
    When I tap on the "Clean" sensory button
    Then the theme should apply Clean Slate white tones
    When I tap on the "Sage" sensory button
    Then the theme should apply Sage natural green tones
    And the application title "Sanctuary" should remain clearly visible throughout
