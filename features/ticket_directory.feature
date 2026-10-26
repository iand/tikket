Feature: Ticket Directory Resolution
  As a user
  I want tk to find .tickets by walking parent directories
  So that I can run commands from any subdirectory of my project

  Background:
    Given a clean tickets directory

  Scenario: Find tickets in current directory
    Given a ticket exists with ID "test-0001" and title "Test ticket"
    When I run "tikket ls"
    Then the command should succeed
    And the output should contain "test-0001"

  Scenario: Find tickets in parent directory
    Given a ticket exists with ID "test-0001" and title "Test ticket"
    And I am in subdirectory "src/components"
    When I run "tikket ls"
    Then the command should succeed
    And the output should contain "test-0001"

  Scenario: Find tickets in grandparent directory
    Given a ticket exists with ID "test-0001" and title "Test ticket"
    And I am in subdirectory "src/components/ui"
    When I run "tikket ls"
    Then the command should succeed
    And the output should contain "test-0001"

  Scenario: Create ticket initializes in current directory when no parent has tickets
    Given the tickets directory does not exist
    And I am in subdirectory "new-project"
    When I run "tikket create 'First ticket'"
    Then the command should succeed
    And the output should match a ticket ID pattern
    And tickets directory should exist in current subdirectory

  Scenario: Error when no tickets directory for read command
    Given the tickets directory does not exist
    When I run "tikket show nonexistent"
    Then the command should fail
    And the output should contain "no .tickets directory found"

  Scenario: Error when no tickets directory in any parent
    Given the tickets directory does not exist
    And I am in subdirectory "orphan/deep/path"
    When I run "tikket ready"
    Then the command should fail
    And the output should contain "no .tickets directory found"

  Scenario: TICKETS_DIR env var takes priority over parent walking
    Given a ticket exists with ID "parent-0001" and title "Parent ticket"
    And a separate tickets directory exists at "other-tickets" with ticket "other-0001" titled "Other ticket"
    And I am in subdirectory "src"
    When I run "tikket ls" with TICKETS_DIR set to "other-tickets"
    Then the command should succeed
    And the output should contain "other-0001"
    And the output should not contain "parent-0001"

  Scenario: TK_DIR env var takes priority over parent walking
    Given a ticket exists with ID "parent-0001" and title "Parent ticket"
    And a separate tickets directory exists at "other-tickets" with ticket "other-0001" titled "Other ticket"
    And I am in subdirectory "src"
    When I run "tikket ls" with TK_DIR set to "other-tickets"
    Then the command should succeed
    And the output should contain "other-0001"
    And the output should not contain "parent-0001"

  Scenario: TK_DIR takes priority over TICKETS_DIR
    Given a separate tickets directory exists at "tk-tickets" with ticket "tk-0001" titled "TK_DIR ticket"
    And a separate tickets directory exists at "legacy-tickets" with ticket "legacy-0001" titled "Legacy ticket"
    When I run "tikket ls" with TK_DIR set to "tk-tickets" and TICKETS_DIR set to "legacy-tickets"
    Then the command should succeed
    And the output should contain "tk-0001"
    And the output should not contain "legacy-0001"

  Scenario: TK_DIR is used by create
    Given a separate tickets directory exists at "tk-tickets" with ticket "tk-0001" titled "Existing"
    When I run "tikket create 'Via TK_DIR' -s via-tk" with TK_DIR set to "tk-tickets"
    Then the command should succeed
    And the output should match pattern "-via-tk$"
    And directory "tk-tickets" should contain a ticket file ending "-via-tk.md"

  Scenario: Missing TK_DIR directory is an error for read commands
    When I run "tikket ls" with TK_DIR set to "does-not-exist"
    Then the command should fail
    And the output should contain "does not exist"

  Scenario: Show command works from subdirectory
    Given a ticket exists with ID "test-0001" and title "Test ticket"
    And I am in subdirectory "src"
    When I run "tikket show test-0001"
    Then the command should succeed
    And the output should contain "id: test-0001"

  Scenario: Dep command works from subdirectory
    Given a ticket exists with ID "task-0001" and title "Main task"
    And a ticket exists with ID "task-0002" and title "Dependency"
    And I am in subdirectory "lib"
    When I run "tikket dep task-0001 task-0002"
    Then the command should succeed
    And the output should contain "Added dependency"

  Scenario: Help command works without tickets directory
    Given the tickets directory does not exist
    When I run "tikket help"
    Then the command should succeed
    And the output should contain "minimal ticket system"
