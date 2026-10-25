Feature: A member can come back after deleting their account

  The member who deleted the account is the only person who can return.
  An organizer unban does not clear this tombstone. Permanent erase stays
  on issue 545. Who else might restore someone, and for how long, is
  discussion 590.

  Scenario: Create, delete, blocked sign-in, then RESTORE
    Given a synthetic member whose email includes the current timestamp
    When that member types DELETE
    Then sign-in is turned off and the directory flag is false
    When that same member types RESTORE
    Then sign-in works again and the directory flag is true

  Scenario: An organizer cannot undo a self-delete
    Given a member has deleted their own account
    When an organizer unbans that member
    Then sign-in stays turned off
