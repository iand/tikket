Feature: Ticket Directory Initialization
  As a user
  I want to initialize a tickets directory explicitly
  So that tickets live in one place regardless of where I run commands

  Background:
    Given the tickets directory does not exist

  Scenario: Init creates .tickets in the current directory outside git
    When I run "tikket init"
    Then the command should succeed
    And the output should contain "Initialized"
    And path ".tickets/.gitkeep" should exist

  Scenario: Init is idempotent
    When I run "tikket init"
    And I run "tikket init"
    Then the command should succeed
    And the output should contain "Already initialized"

  Scenario: Init in a git repository subdirectory creates .tickets at the repository root
    Given the test directory is a git repository
    And I am in subdirectory "src/deep"
    When I run "tikket init"
    Then the command should succeed
    And path ".tickets/.gitkeep" should exist
    And path "src/deep/.tickets" should not exist

  Scenario: Tickets created from a subdirectory after init go to the repository root
    Given the test directory is a git repository
    And I am in subdirectory "src"
    When I run "tikket init"
    And I run "tikket create 'From src' -s from-src"
    Then the command should succeed
    And directory ".tickets" should contain a ticket file ending "-from-src.md"
    And path "src/.tickets" should not exist

  Scenario: Init outside git uses the current subdirectory
    Given I am in subdirectory "work"
    When I run "tikket init"
    Then the command should succeed
    And path "work/.tickets/.gitkeep" should exist

  Scenario: Init uses TK_DIR when set
    When I run "tikket init" with TK_DIR set to "custom/tickets"
    Then the command should succeed
    And path "custom/tickets/.gitkeep" should exist
    And path ".tickets" should not exist

  Scenario: Init uses TICKETS_DIR when set
    When I run "tikket init" with TICKETS_DIR set to "legacy/tickets"
    Then the command should succeed
    And path "legacy/tickets/.gitkeep" should exist

  Scenario: Init notes when it hides a tickets directory further up
    Given a clean tickets directory
    And I am in subdirectory "inner"
    When I run "tikket init"
    Then the command should succeed
    And path "inner/.tickets/.gitkeep" should exist
    And the output should contain "hides"

  Scenario: Init refuses when the target is a file
    Given a file exists at "custom/tickets"
    When I run "tikket init" with TK_DIR set to "custom/tickets"
    Then the command should fail
    And the output should contain "exists and is not a directory"

  Scenario: Init takes no arguments
    When I run "tikket init somewhere"
    Then the command should fail
    And the output should contain "Usage:"
    And path ".tickets" should not exist

  Scenario: A freshly initialized directory works with other commands
    When I run "tikket init"
    And I run "tikket ls"
    Then the command should succeed
    And the output should be empty

  Scenario: The .gitkeep file does not trouble check
    When I run "tikket init"
    And I run "tikket check"
    Then the command should succeed
    And the output should be "No problems found"

  Scenario: Missing directory error points at init
    When I run "tikket ls"
    Then the command should fail
    And the output should contain "Run 'tk init' to initialize"
