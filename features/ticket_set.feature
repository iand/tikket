Feature: Ticket Set
  As a user
  I want to change ticket fields after creation
  So that I do not have to edit YAML by hand

  Background:
    Given a clean tickets directory
    And a ticket exists with ID "set-0001" and title "Original title"
    And a ticket exists with ID "set-0002" and title "Other ticket"

  Scenario: Set title
    When I run "tikket set set-0001 title 'New title'"
    Then the command should succeed
    And the output should be "Updated set-0001: title"
    And ticket "set-0001" should contain "# New title"
    And ticket "set-0001" should not contain "# Original title"

  Scenario: Set title with characters special to sed
    When I run "tikket set set-0001 title 'Fix a/b & c\d'"
    Then the command should succeed
    And ticket "set-0001" should contain "# Fix a/b & c\d"

  Scenario: Set empty title is refused
    When I run "tikket set set-0001 title ''"
    Then the command should fail
    And the output should contain "title cannot be empty"

  Scenario: Set type
    When I run "tikket set set-0001 type bug"
    Then the command should succeed
    And ticket "set-0001" should have field "type" with value "bug"

  Scenario: Set invalid type
    When I run "tikket set set-0001 type story"
    Then the command should fail
    And the output should contain "invalid type 'story'"
    And ticket "set-0001" should have field "type" with value "task"

  Scenario: Set priority
    When I run "tikket set set-0001 priority 0"
    Then the command should succeed
    And ticket "set-0001" should have field "priority" with value "0"

  Scenario: Set invalid priority
    When I run "tikket set set-0001 priority 5"
    Then the command should fail
    And the output should contain "invalid priority '5'"

  Scenario: Set assignee with special characters
    When I run "tikket set set-0001 assignee 'Ann/Bee & Co'"
    Then the command should succeed
    And ticket "set-0001" should have field "assignee" with value "Ann/Bee & Co"

  Scenario: Clear assignee
    Given ticket "set-0001" has field "assignee" with value "someone"
    When I run "tikket set set-0001 assignee ''"
    Then the command should succeed
    And ticket "set-0001" should not have field "assignee"

  Scenario: Set parent resolves partial ID
    When I run "tikket set set-0001 parent 0002"
    Then the command should succeed
    And ticket "set-0001" should have field "parent" with value "set-0002"

  Scenario: Set parent to itself is refused
    When I run "tikket set set-0001 parent set-0001"
    Then the command should fail
    And the output should contain "cannot be its own parent"

  Scenario: Set parent that would form a cycle is refused
    Given ticket "set-0002" has field "parent" with value "set-0001"
    When I run "tikket set set-0001 parent set-0002"
    Then the command should fail
    And the output should contain "parent would create a cycle: set-0001 -> set-0002 -> set-0001"
    And ticket "set-0001" should not have field "parent"

  Scenario: Set parent to non-existent ticket
    When I run "tikket set set-0001 parent nonexistent"
    Then the command should fail
    And the output should contain "Error: ticket 'nonexistent' not found"

  Scenario: Clear parent
    Given ticket "set-0001" has field "parent" with value "set-0002"
    When I run "tikket set set-0001 parent ''"
    Then the command should succeed
    And ticket "set-0001" should not have field "parent"

  Scenario: Set tags normalises spacing
    When I run "tikket set set-0001 tags 'ui, backend,urgent'"
    Then the command should succeed
    And ticket "set-0001" should have field "tags" with value "[ui, backend, urgent]"

  Scenario: Set does not touch body lines that look like fields
    When I run "tikket add-note set-0001 'priority: keep this line'"
    And I run "tikket set set-0001 priority 1"
    Then the command should succeed
    And ticket "set-0001" should contain "priority: keep this line"
    And ticket "set-0001" should have field "priority" with value "1"

  Scenario Outline: Fields with dedicated commands cannot be set
    When I run "tikket set set-0001 <field> x"
    Then the command should fail
    And the output should contain "cannot be set directly"

    Examples:
      | field      |
      | status     |
      | deps       |
      | links      |
      | id         |
      | created    |
      | closed     |
      | resolution |

  Scenario: Unknown field
    When I run "tikket set set-0001 colour blue"
    Then the command should fail
    And the output should contain "unknown field 'colour'"

  Scenario: Set with missing arguments
    When I run "tikket set set-0001 title"
    Then the command should fail
    And the output should contain "set <id> <field> <value>"
    And the output should contain "Fields: title type priority assignee parent tags"
