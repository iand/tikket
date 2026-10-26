Feature: Ticket Listing
  As a user
  I want to list tickets in various ways
  So that I can see what work needs to be done

  Background:
    Given a clean tickets directory

  Scenario: List all tickets
    Given a ticket exists with ID "list-0001" and title "First ticket"
    And a ticket exists with ID "list-0002" and title "Second ticket"
    When I run "ticket ls"
    Then the command should succeed
    And the output should contain "list-0001"
    And the output should contain "list-0002"

  Scenario: List command alias works
    Given a ticket exists with ID "list-0001" and title "First ticket"
    When I run "ticket list"
    Then the command should succeed
    And the output should contain "list-0001"

  Scenario: List shows ticket format correctly
    Given a ticket exists with ID "list-0001" and title "My ticket"
    When I run "ticket ls"
    Then the command should succeed
    And the output should match pattern "list-0001\s+\[open\]\s+-\s+My ticket"

  Scenario: List with status filter
    Given a ticket exists with ID "list-0001" and title "Open ticket"
    And a ticket exists with ID "list-0002" and title "Closed ticket"
    And ticket "list-0002" has status "closed"
    When I run "ticket ls --status=open"
    Then the command should succeed
    And the output should contain "list-0001"
    And the output should not contain "list-0002"

  Scenario: List shows dependencies
    Given a ticket exists with ID "list-0001" and title "Main ticket"
    And a ticket exists with ID "list-0002" and title "Dep ticket"
    And ticket "list-0001" depends on "list-0002"
    When I run "ticket ls"
    Then the command should succeed
    And the output should contain "<- [list-0002]"

  Scenario: List with no tickets returns nothing
    When I run "ticket ls"
    Then the output should be empty

  Scenario: Ready shows tickets with no deps and with closed deps
    Given a ticket exists with ID "ready-001" and title "Ready ticket"
    And a ticket exists with ID "ready-002" and title "Unblocked ticket"
    And a ticket exists with ID "ready-003" and title "Dependency"
    And ticket "ready-002" depends on "ready-003"
    And ticket "ready-003" has status "closed"
    When I run "ticket ready"
    Then the command should succeed
    And the output should contain "ready-001"
    And the output should contain "ready-002"

  Scenario: Ready excludes tickets with unclosed deps
    Given a ticket exists with ID "ready-001" and title "Blocked ticket"
    And a ticket exists with ID "ready-002" and title "Open dependency"
    And ticket "ready-001" depends on "ready-002"
    When I run "ticket ready"
    Then the command should succeed
    And the output should not contain "ready-001"
    And the output should contain "ready-002"

  Scenario: Ready shows tickets when deps are closed
    Given a ticket exists with ID "ready-001" and title "Main ticket"
    And a ticket exists with ID "ready-002" and title "Closed dependency"
    And ticket "ready-001" depends on "ready-002"
    And ticket "ready-002" has status "closed"
    When I run "ticket ready"
    Then the command should succeed
    And the output should contain "ready-001"

  Scenario: Ready excludes closed tickets
    Given a ticket exists with ID "ready-001" and title "Closed ticket"
    And ticket "ready-001" has status "closed"
    When I run "ticket ready"
    Then the command should succeed
    And the output should not contain "ready-001"

  Scenario: Ready shows priority in output
    Given a ticket exists with ID "ready-001" and title "Priority ticket"
    When I run "ticket ready"
    Then the command should succeed
    And the output should match pattern "ready-001\s+\[P2\]\[open\]\s+-\s+Priority ticket"

  Scenario: Ready sorts by priority then ID
    Given a ticket exists with ID "ready-003" and title "Low priority" with priority 3
    And a ticket exists with ID "ready-001" and title "High priority" with priority 1
    And a ticket exists with ID "ready-002" and title "Also high priority" with priority 1
    When I run "ticket ready"
    Then the command should succeed
    And the output line 1 should contain "ready-001"
    And the output line 2 should contain "ready-002"
    And the output line 3 should contain "ready-003"

  Scenario: Blocked shows tickets with unclosed deps
    Given a ticket exists with ID "block-001" and title "Blocked ticket"
    And a ticket exists with ID "block-002" and title "Blocker ticket"
    And ticket "block-001" depends on "block-002"
    When I run "ticket blocked"
    Then the command should succeed
    And the output should contain "block-001"
    And the output should contain "<- [block-002]"

  Scenario: Blocked excludes tickets with all deps closed
    Given a ticket exists with ID "block-001" and title "Unblocked ticket"
    And a ticket exists with ID "block-002" and title "Closed blocker"
    And ticket "block-001" depends on "block-002"
    And ticket "block-002" has status "closed"
    When I run "ticket blocked"
    Then the command should succeed
    And the output should not contain "block-001"

  Scenario: Blocked excludes closed tickets
    Given a ticket exists with ID "block-001" and title "Closed blocked"
    And a ticket exists with ID "block-002" and title "Blocker"
    And ticket "block-001" depends on "block-002"
    And ticket "block-001" has status "closed"
    When I run "ticket blocked"
    Then the command should succeed
    And the output should not contain "block-001"

  Scenario: Blocked shows only unclosed blockers
    Given a ticket exists with ID "block-001" and title "Blocked ticket"
    And a ticket exists with ID "block-002" and title "Open blocker"
    And a ticket exists with ID "block-003" and title "Closed blocker"
    And ticket "block-001" depends on "block-002"
    And ticket "block-001" depends on "block-003"
    And ticket "block-003" has status "closed"
    When I run "ticket blocked"
    Then the command should succeed
    And the output should contain "<- [block-002]"
    And the output should not contain "block-003"

  Scenario: Closed shows recently closed tickets
    Given a ticket exists with ID "done-0001" and title "Done ticket"
    And ticket "done-0001" has status "closed"
    When I run "ticket closed"
    Then the command should succeed
    And the output should contain "done-0001"
    And the output should contain "[closed]"
    And the output should contain "Done ticket"

  Scenario: Closed respects limit
    Given a ticket exists with ID "done-0001" and title "First done"
    And a ticket exists with ID "done-0002" and title "Second done"
    And ticket "done-0001" has status "closed"
    And ticket "done-0002" has status "closed"
    When I run "ticket closed --limit=1"
    Then the command should succeed
    And the output line count should be 1

  Scenario: Closed excludes open tickets
    Given a ticket exists with ID "done-0001" and title "Open ticket"
    When I run "ticket closed"
    Then the command should succeed
    And the output should not contain "done-0001"

  Scenario: Ready excludes in-progress tickets by default
    Given a ticket exists with ID "ready-001" and title "Open ticket"
    And a ticket exists with ID "ready-002" and title "Active ticket"
    And ticket "ready-002" has status "in_progress"
    When I run "ticket ready"
    Then the command should succeed
    And the output should contain "ready-001"
    And the output should not contain "ready-002"

  Scenario: Ready with --all includes in-progress tickets
    Given a ticket exists with ID "ready-001" and title "Open ticket"
    And a ticket exists with ID "ready-002" and title "Active ticket"
    And ticket "ready-002" has status "in_progress"
    When I run "ticket ready --all"
    Then the command should succeed
    And the output should contain "ready-001"
    And the output should contain "ready-002"

  Scenario: Next shows the highest priority ready ticket
    Given a ticket exists with ID "ready-003" and title "Low priority" with priority 3
    And a ticket exists with ID "ready-001" and title "High priority" with priority 1
    And a ticket exists with ID "ready-002" and title "Blocked high priority" with priority 0
    And ticket "ready-002" depends on "ready-003"
    When I run "ticket next"
    Then the command should succeed
    And the output line count should be 1
    And the output should match pattern "^ready-001\s+\[P1\]\[open\]\s+-\s+High priority$"

  Scenario: Next respects filters
    Given a ticket exists with ID "ready-001" and title "Mine" with priority 3
    And a ticket exists with ID "ready-002" and title "Theirs" with priority 1
    And ticket "ready-001" has field "assignee" with value "agent-1"
    When I run "ticket next -a agent-1"
    Then the command should succeed
    And the output should contain "ready-001"

  Scenario: Next with nothing ready prints nothing
    Given a ticket exists with ID "ready-001" and title "Done"
    And ticket "ready-001" has status "closed"
    When I run "ticket next"
    Then the command should succeed
    And the output should be empty

  Scenario: Closed sorts by closed timestamp, newest first
    Given a ticket exists with ID "done-0001" and title "Closed in March"
    And a ticket exists with ID "done-0002" and title "Closed in January"
    And a ticket exists with ID "done-0003" and title "Closed in February"
    And ticket "done-0001" has status "closed"
    And ticket "done-0002" has status "closed"
    And ticket "done-0003" has status "closed"
    And ticket "done-0001" has field "closed" with value "2024-03-01T00:00:00Z"
    And ticket "done-0002" has field "closed" with value "2024-01-01T00:00:00Z"
    And ticket "done-0003" has field "closed" with value "2024-02-01T00:00:00Z"
    When I run "ticket closed"
    Then the command should succeed
    And the output line 1 should contain "done-0001"
    And the output line 2 should contain "done-0003"
    And the output line 3 should contain "done-0002"

  Scenario: Closed lists tickets without a timestamp after timestamped ones
    Given a ticket exists with ID "done-0001" and title "Legacy close"
    And a ticket exists with ID "done-0002" and title "Recorded close"
    And ticket "done-0001" has status "closed"
    And ticket "done-0002" has status "closed"
    And ticket "done-0002" has field "closed" with value "2024-01-01T00:00:00Z"
    When I run "ticket closed"
    Then the output line 1 should contain "done-0002"
    And the output line 2 should contain "done-0001"

  Scenario: Closed limit applies after filtering
    Given a ticket exists with ID "done-0001" and title "Closed ticket"
    And ticket "done-0001" has status "closed"
    And 120 open tickets exist
    When I run "ticket closed --limit=5"
    Then the command should succeed
    And the output should contain "done-0001"

  Scenario: Closed shows resolution
    Given a ticket exists with ID "done-0001" and title "Dropped"
    When I run "ticket close done-0001 -r wontfix"
    And I run "ticket closed"
    Then the output should match pattern "done-0001\s+\[wontfix\]\s+-\s+Dropped"
