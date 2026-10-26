Feature: Ticket Creation
  As a user
  I want to create tickets with various options
  So that I can track tasks in my project

  Background:
    Given a clean tickets directory

  Scenario: Create a basic ticket with title
    When I run "tikket create 'My first ticket'"
    Then the command should succeed
    And the output should match a ticket ID pattern
    And a ticket file should exist with title "My first ticket"

  Scenario: Create a ticket with default title
    When I run "tikket create"
    Then the command should succeed
    And the output should match a ticket ID pattern
    And a ticket file should exist with title "Untitled"

  Scenario: Create a ticket with description
    When I run "tikket create 'Test ticket' -d 'This is the description'"
    Then the command should succeed
    And the created ticket should contain "This is the description"

  Scenario: Create a ticket with type
    When I run "tikket create 'Bug ticket' -t bug"
    Then the command should succeed
    And the created ticket should have field "type" with value "bug"

  Scenario: Create a ticket with priority
    When I run "tikket create 'High priority' -p 0"
    Then the command should succeed
    And the created ticket should have field "priority" with value "0"

  Scenario: Create a ticket with assignee
    When I run "tikket create 'Assigned ticket' -a 'John Doe'"
    Then the command should succeed
    And the created ticket should have field "assignee" with value "John Doe"

  Scenario: Create a ticket with invalid type
    When I run "tikket create 'Bad type' -t story"
    Then the command should fail
    And the output should contain "invalid type 'story'"

  Scenario: Create a ticket with invalid priority
    When I run "tikket create 'Bad priority' -p 7"
    Then the command should fail
    And the output should contain "invalid priority '7'"

  Scenario: Create uses TK_ASSIGNEE as default assignee
    When I run "tikket create 'Agent ticket'" with TK_ASSIGNEE set to "agent-1"
    Then the command should succeed
    And the created ticket should have field "assignee" with value "agent-1"

  Scenario: Create uses the recorded prefix
    Given a file exists at ".tickets/.prefix" containing "sf"
    When I run "tikket create 'Recorded prefix'"
    Then the command should succeed
    And the output should match pattern "^sf-[a-z0-9]{4}$"

  Scenario: Slug IDs use the recorded prefix
    Given a file exists at ".tickets/.prefix" containing "sf"
    When I run "tikket create 'Fix login' --slug fix-login"
    Then the command should succeed
    And the output should be "sf-fix-login"

  Scenario: Create from a subdirectory takes the prefix from the project directory
    Given a file exists at "my-shop/.tickets/.keep" containing ""
    And I am in subdirectory "my-shop/src/deep"
    When I run "tikket create 'From deep' --slug from-deep"
    Then the command should succeed
    And the output should be "ms-from-deep"

  Scenario: Recorded prefix wins over the directory name
    Given a file exists at "project/.tickets/.prefix" containing "sf"
    And I am in subdirectory "project"
    When I run "tikket create 'In project dir' --slug x"
    Then the command should succeed
    And the output should be "sf-x"

  Scenario: Create a ticket with slug
    When I run "tikket create 'Fix login' --slug fix-login"
    Then the command should succeed
    And the output should match pattern "^[a-z0-9]+-fix-login$"
    And a ticket file should exist with title "Fix login"

  Scenario: Create a ticket with short slug flag
    When I run "tikket create 'Fix login' -s fix-login"
    Then the command should succeed
    And the output should match pattern "^[a-z0-9]+-fix-login$"

  Scenario: Slug is written to the id field
    When I run "tikket create 'Fix login' --slug fix-login"
    Then the command should succeed
    And the created ticket should contain "-fix-login"

  Scenario Outline: Create a ticket with invalid slug
    When I run "tikket create 'Bad slug' --slug '<slug>'"
    Then the command should fail
    And the output should contain "invalid slug"

    Examples:
      | slug       |
      | Fix-Login  |
      | fix_login  |
      | fix--login |
      | -fix       |
      | fix-       |
      | fix login  |

  Scenario: Create a ticket with duplicate slug
    When I run "tikket create 'First' --slug fix-login"
    And I run "tikket create 'Second' --slug fix-login"
    Then the command should fail
    And the output should contain "already exists"

  Scenario: Create a ticket with parent
    Given a ticket exists with ID "parent-001" and title "Parent ticket"
    When I run "tikket create 'Child ticket' --parent parent-001"
    Then the command should succeed
    And the created ticket should have field "parent" with value "parent-001"

  Scenario: Create a ticket with design notes
    When I run "tikket create 'Design ticket' --design 'Use microservices'"
    Then the command should succeed
    And the created ticket should contain "## Design"
    And the created ticket should contain "Use microservices"

  Scenario: Create a ticket with acceptance criteria
    When I run "tikket create 'Story ticket' --acceptance 'Should pass all tests'"
    Then the command should succeed
    And the created ticket should contain "## Acceptance Criteria"
    And the created ticket should contain "Should pass all tests"

  Scenario: Ticket has default status open
    When I run "tikket create 'New ticket'"
    Then the command should succeed
    And the created ticket should have field "status" with value "open"

  Scenario: Ticket has default priority 2
    When I run "tikket create 'Normal priority'"
    Then the command should succeed
    And the created ticket should have field "priority" with value "2"

  Scenario: Ticket has default type task
    When I run "tikket create 'Default type'"
    Then the command should succeed
    And the created ticket should have field "type" with value "task"

  Scenario: Ticket has empty deps by default
    When I run "tikket create 'No deps'"
    Then the command should succeed
    And the created ticket should have field "deps" with value "[]"

  Scenario: Ticket has empty links by default
    When I run "tikket create 'No links'"
    Then the command should succeed
    And the created ticket should have field "links" with value "[]"

  Scenario: Ticket has created timestamp
    When I run "tikket create 'Timestamped'"
    Then the command should succeed
    And the created ticket should have a valid created timestamp

  Scenario: Tickets directory created on demand
    Given the tickets directory does not exist
    When I run "tikket create 'First ticket'"
    Then the command should succeed
    And the tickets directory should exist
