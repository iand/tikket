Feature: Ticket Status Management
  As a user
  I want to change ticket statuses
  So that I can track progress on tasks

  Background:
    Given a clean tickets directory
    And a ticket exists with ID "test-0001" and title "Test ticket"

  Scenario: Set status to in_progress
    When I run "ticket status test-0001 in_progress"
    Then the command should succeed
    And the output should be "Updated test-0001 -> in_progress"
    And ticket "test-0001" should have field "status" with value "in_progress"

  Scenario: Set status to closed
    When I run "ticket status test-0001 closed"
    Then the command should succeed
    And the output should be "Updated test-0001 -> closed"
    And ticket "test-0001" should have field "status" with value "closed"

  Scenario: Set status to open
    Given ticket "test-0001" has status "closed"
    When I run "ticket status test-0001 open"
    Then the command should succeed
    And the output should be "Updated test-0001 -> open"
    And ticket "test-0001" should have field "status" with value "open"

  Scenario: Start command sets status to in_progress
    When I run "ticket start test-0001"
    Then the command should succeed
    And the output should be "Updated test-0001 -> in_progress"
    And ticket "test-0001" should have field "status" with value "in_progress"

  Scenario: Close command sets status to closed
    When I run "ticket close test-0001"
    Then the command should succeed
    And the output should be "Updated test-0001 -> closed"
    And ticket "test-0001" should have field "status" with value "closed"

  Scenario: Reopen command sets status to open
    Given ticket "test-0001" has status "closed"
    When I run "ticket reopen test-0001"
    Then the command should succeed
    And the output should be "Updated test-0001 -> open"
    And ticket "test-0001" should have field "status" with value "open"

  Scenario: Invalid status value
    When I run "ticket status test-0001 invalid"
    Then the command should fail
    And the output should contain "Error: invalid status 'invalid'"
    And the output should contain "open in_progress closed"

  Scenario: Status of non-existent ticket
    When I run "ticket status nonexistent open"
    Then the command should fail
    And the output should contain "Error: ticket 'nonexistent' not found"

  Scenario: Status command with partial ID
    When I run "ticket status 0001 in_progress"
    Then the command should succeed
    And ticket "test-0001" should have field "status" with value "in_progress"

  Scenario: Closing records a timestamp and default resolution
    When I run "ticket close test-0001"
    Then the command should succeed
    And ticket "test-0001" should have field "closed" matching "\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z"
    And ticket "test-0001" should have field "resolution" with value "done"

  Scenario: Status command to closed also records a timestamp
    When I run "ticket status test-0001 closed"
    Then the command should succeed
    And ticket "test-0001" should have field "closed" matching "\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z"

  Scenario: Closing an already closed ticket keeps the original timestamp
    Given ticket "test-0001" has status "closed"
    And ticket "test-0001" has field "closed" with value "2024-02-01T00:00:00Z"
    When I run "ticket close test-0001"
    Then the command should succeed
    And ticket "test-0001" should have field "closed" with value "2024-02-01T00:00:00Z"

  Scenario: Reopen clears closed timestamp and resolution
    When I run "ticket close test-0001 -r wontfix"
    And I run "ticket reopen test-0001"
    Then the command should succeed
    And ticket "test-0001" should not have field "closed"
    And ticket "test-0001" should not have field "resolution"

  Scenario: Start clears closed timestamp
    When I run "ticket close test-0001"
    And I run "ticket start test-0001"
    Then ticket "test-0001" should not have field "closed"

  Scenario Outline: Close with resolution
    When I run "ticket close test-0001 --resolution <resolution>"
    Then the command should succeed
    And ticket "test-0001" should have field "resolution" with value "<resolution>"

    Examples:
      | resolution |
      | done       |
      | wontfix    |
      | duplicate  |

  Scenario: Close with invalid resolution
    When I run "ticket close test-0001 -r abandoned"
    Then the command should fail
    And the output should contain "invalid resolution 'abandoned'"
    And ticket "test-0001" should have field "status" with value "open"

  Scenario: Close with message adds an attributed note
    When I run "ticket close test-0001 -m 'Fixed in PR 12'" with TK_ASSIGNEE set to "agent-1"
    Then the command should succeed
    And ticket "test-0001" should have field "status" with value "closed"
    And ticket "test-0001" should contain "## Notes"
    And ticket "test-0001" should contain "Z** agent-1"
    And ticket "test-0001" should contain "Fixed in PR 12"

  Scenario: Close refuses a ticket with open children
    Given a ticket exists with ID "child-001" and title "Open child" with parent "test-0001"
    When I run "ticket close test-0001"
    Then the command should fail
    And the output should contain "has open children"
    And the output should contain "child-001 [open] Open child"
    And ticket "test-0001" should have field "status" with value "open"

  Scenario: Status command also refuses to close a ticket with open children
    Given a ticket exists with ID "child-001" and title "Open child" with parent "test-0001"
    When I run "ticket status test-0001 closed"
    Then the command should fail
    And the output should contain "has open children"

  Scenario: Close with force closes a ticket with open children
    Given a ticket exists with ID "child-001" and title "Open child" with parent "test-0001"
    When I run "ticket close test-0001 --force"
    Then the command should succeed
    And ticket "test-0001" should have field "status" with value "closed"

  Scenario: Close allows a ticket whose children are closed
    Given a ticket exists with ID "child-001" and title "Done child" with parent "test-0001"
    And ticket "child-001" has status "closed"
    When I run "ticket close test-0001"
    Then the command should succeed

  Scenario: Close with unknown option
    When I run "ticket close test-0001 --bogus"
    Then the command should fail
    And the output should contain "Unknown option: --bogus"
