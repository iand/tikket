Feature: Ticket Check
  As an agent
  I want to validate the tickets directory
  So that broken references do not silently block work

  Background:
    Given a clean tickets directory

  Scenario: Valid tickets pass
    Given a ticket exists with ID "chk-0001" and title "First"
    And a ticket exists with ID "chk-0002" and title "Second" with parent "chk-0001"
    And ticket "chk-0002" depends on "chk-0001"
    And ticket "chk-0001" is linked to "chk-0002"
    When I run "ticket check"
    Then the command should succeed
    And the output should be "No problems found"

  Scenario: Empty tickets directory passes
    When I run "ticket check"
    Then the command should succeed
    And the output should be "No problems found"

  Scenario: Missing dependency is reported
    Given a ticket exists with ID "chk-0001" and title "First"
    And ticket "chk-0001" depends on "ghost-01"
    When I run "ticket check"
    Then the command should fail
    And the output should contain "chk-0001: dependency ghost-01 does not exist"
    And the output should contain "1 problem(s) found"

  Scenario: Missing parent and link are reported
    Given a ticket exists with ID "chk-0001" and title "First" with parent "ghost-01"
    And ticket "chk-0001" has field "links" with value "[ghost-02]"
    When I run "ticket check"
    Then the command should fail
    And the output should contain "chk-0001: parent ghost-01 does not exist"
    And the output should contain "chk-0001: link ghost-02 does not exist"

  Scenario: One-sided link is reported
    Given a ticket exists with ID "chk-0001" and title "First"
    And a ticket exists with ID "chk-0002" and title "Second"
    And ticket "chk-0001" has field "links" with value "[chk-0002]"
    When I run "ticket check"
    Then the command should fail
    And the output should contain "chk-0001: link to chk-0002 is not reciprocated"

  Scenario: Self references are reported
    Given a ticket exists with ID "chk-0001" and title "First" with parent "chk-0001"
    And ticket "chk-0001" has field "deps" with value "[chk-0001]"
    When I run "ticket check"
    Then the command should fail
    And the output should contain "chk-0001: depends on itself"
    And the output should contain "chk-0001: is its own parent"

  Scenario: Parent cycle is reported
    Given a ticket exists with ID "chk-0001" and title "First" with parent "chk-0002"
    And a ticket exists with ID "chk-0002" and title "Second" with parent "chk-0001"
    When I run "ticket check"
    Then the command should fail
    And the output should contain "chk-0001: parent chain forms a cycle"

  Scenario: Invalid field values are reported
    Given a ticket exists with ID "chk-0001" and title "First"
    And ticket "chk-0001" has field "status" with value "done"
    And ticket "chk-0001" has field "type" with value "story"
    And ticket "chk-0001" has field "priority" with value "9"
    When I run "ticket check"
    Then the command should fail
    And the output should contain "chk-0001: invalid status done"
    And the output should contain "chk-0001: invalid type story"
    And the output should contain "chk-0001: invalid priority 9"

  Scenario: Resolution on an open ticket is reported
    Given a ticket exists with ID "chk-0001" and title "First"
    And ticket "chk-0001" has field "resolution" with value "done"
    When I run "ticket check"
    Then the command should fail
    And the output should contain "chk-0001: resolution set on ticket that is not closed"

  Scenario: ID that does not match filename is reported
    Given a ticket file "chk-0001.md" with content
      """
      ---
      id: other-01
      status: open
      deps: []
      links: []
      ---
      # Mismatched
      """
    When I run "ticket check"
    Then the command should fail
    And the output should contain "chk-0001: id field other-01 does not match filename"

  Scenario: Malformed frontmatter is reported
    Given a ticket file "chk-0001.md" with content
      """
      # No frontmatter here
      """
    And a ticket file "chk-0002.md" with content
      """
      ---
      id: chk-0002
      status: open
      """
    When I run "ticket check"
    Then the command should fail
    And the output should contain "chk-0001: missing frontmatter"
    And the output should contain "chk-0002: unterminated frontmatter"

  Scenario: Closed tickets made by close pass check
    Given a ticket exists with ID "chk-0001" and title "First"
    When I run "ticket close chk-0001 -r wontfix"
    And I run "ticket check"
    Then the command should succeed
