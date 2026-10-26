Feature: Ticket Notes
  As a user
  I want to add notes to tickets
  So that I can track progress and updates

  Background:
    Given a clean tickets directory
    And a ticket exists with ID "note-0001" and title "Test ticket"

  Scenario: Add a note to ticket
    When I run "tikket add-note note-0001 'This is my note'"
    Then the command should succeed
    And the output should be "Note added to note-0001"
    And ticket "note-0001" should contain "## Notes"
    And ticket "note-0001" should contain "This is my note"

  Scenario: Note has timestamp
    When I run "tikket add-note note-0001 'Timestamped note'"
    Then the command should succeed
    And ticket "note-0001" should contain a timestamp in notes

  Scenario: Add multiple notes
    When I run "tikket add-note note-0001 'First note'"
    And I run "tikket add-note note-0001 'Second note'"
    Then ticket "note-0001" should contain "First note"
    And ticket "note-0001" should contain "Second note"

  Scenario: Add note to ticket that already has notes section
    Given ticket "note-0001" has a notes section
    When I run "tikket add-note note-0001 'Additional note'"
    Then the command should succeed
    And ticket "note-0001" should contain "Additional note"

  Scenario: Add note with empty string adds timestamp-only note
    When I run "tikket add-note note-0001 ''"
    Then the command should succeed
    And the output should be "Note added to note-0001"
    And ticket "note-0001" should contain "## Notes"

  Scenario: Add note to non-existent ticket
    When I run "tikket add-note nonexistent 'My note'"
    Then the command should fail
    And the output should contain "Error: ticket 'nonexistent' not found"

  Scenario: Add note with partial ID
    When I run "tikket add-note 0001 'Partial ID note'"
    Then the command should succeed
    And the output should be "Note added to note-0001"

  Scenario: Note records author from TK_ASSIGNEE
    When I run "tikket add-note note-0001 'Agent note'" with TK_ASSIGNEE set to "agent-1"
    Then the command should succeed
    And ticket "note-0001" should contain "Z** agent-1"

  Scenario: Note records explicit author
    When I run "tikket add-note note-0001 -a reviewer 'Looks good'"
    Then the command should succeed
    And ticket "note-0001" should contain "Z** reviewer"
    And ticket "note-0001" should contain "Looks good"
    And ticket "note-0001" should not contain "-a reviewer"

  Scenario: Note author flag without value
    When I run "tikket add-note note-0001 -a"
    Then the command should fail
    And the output should contain "Usage:"
