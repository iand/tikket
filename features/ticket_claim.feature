Feature: Ticket Claim
  As an agent sharing a tickets directory with other agents
  I want to claim a ticket atomically
  So that two agents never work on the same ticket

  Background:
    Given a clean tickets directory
    And a ticket exists with ID "claim-001" and title "Claimable"

  Scenario: Claim an open ticket
    When I run "tikket claim claim-001" with TK_ASSIGNEE set to "agent-1"
    Then the command should succeed
    And the output should be "Claimed claim-001 for agent-1"
    And ticket "claim-001" should have field "status" with value "in_progress"
    And ticket "claim-001" should have field "assignee" with value "agent-1"

  Scenario: Claim with explicit assignee
    When I run "tikket claim claim-001 -a agent-2"
    Then the command should succeed
    And ticket "claim-001" should have field "assignee" with value "agent-2"

  Scenario: Claim is idempotent for the same assignee
    When I run "tikket claim claim-001 -a agent-1"
    And I run "tikket claim claim-001 -a agent-1"
    Then the command should succeed
    And the output should be "Claimed claim-001 for agent-1"

  Scenario: Claim fails when another agent has the ticket
    When I run "tikket claim claim-001 -a agent-1"
    And I run "tikket claim claim-001 -a agent-2"
    Then the command should fail
    And the output should contain "already claimed by agent-1"
    And ticket "claim-001" should have field "assignee" with value "agent-1"

  Scenario: Claim takes an open ticket that has an assignee
    Given ticket "claim-001" has field "assignee" with value "planner"
    When I run "tikket claim claim-001 -a agent-1"
    Then the command should succeed
    And ticket "claim-001" should have field "assignee" with value "agent-1"

  Scenario: Claim fails on a closed ticket
    Given ticket "claim-001" has status "closed"
    When I run "tikket claim claim-001 -a agent-1"
    Then the command should fail
    And the output should contain "claim-001 is closed"

  Scenario: Claimed ticket leaves ready list
    When I run "tikket claim claim-001 -a agent-1"
    And I run "tikket ready"
    Then the output should not contain "claim-001"

  Scenario: Claim fails when lock is held
    Given a lock exists for ticket "claim-001"
    When I run "tikket claim claim-001 -a agent-1"
    Then the command should fail
    And the output should contain "could not acquire lock"

  Scenario: Claim leaves no lock behind
    When I run "tikket claim claim-001 -a agent-1"
    Then no lock should exist for ticket "claim-001"

  Scenario: Concurrent claims have a single winner
    When 8 agents claim "claim-001" at the same time
    Then exactly 1 claim should succeed
    And no lock should exist for ticket "claim-001"
