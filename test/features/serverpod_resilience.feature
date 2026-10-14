Feature: Serverpod 4 Resilient Client Integration
  As a hackathon judge or end user
  I want the client to seamlessly fall back to local cached reflections within 800ms
  So that the app never crashes or presents a frozen spinner if a local backend is offline

  Scenario: Operating in resilient offline fallback mode
    Given a ServerpodPostRepository initialized with an unreachable server URL
    When the client requests reflections for space "prayer"
    Then it should yield seeded fellowship reflections without throwing an unhandled exception
    And the header should display the "Serverpod 4 (Resilient Mode)" status indicator

  Scenario: Server-side Quiet Digest aggregation banner
    Given the Sanctuary application is open
    Then I should see the Quiet Digest banner summarizing community care
    And it should display aggregate reflections and care affirmation totals
