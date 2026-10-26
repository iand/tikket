Feature: Ticket Links
  As a user
  I want to create symmetric links between tickets
  So that I can track related tickets

  Background:
    Given a clean tickets directory
    And a ticket exists with ID "link-0001" and title "First ticket"
    And a ticket exists with ID "link-0002" and title "Second ticket"
    And a ticket exists with ID "link-0003" and title "Third ticket"

  Scenario: Link two tickets
    When I run "ticket link link-0001 link-0002"
    Then the command should succeed
    And the output should contain "Added 2 link(s) between 2 tickets"
    And ticket "link-0001" should have "link-0002" in links
    And ticket "link-0002" should have "link-0001" in links

  Scenario: Link three tickets
    When I run "ticket link link-0001 link-0002 link-0003"
    Then the command should succeed
    And the output should contain "Added 6 link(s) between 3 tickets"
    And ticket "link-0001" should have "link-0002" in links
    And ticket "link-0001" should have "link-0003" in links
    And ticket "link-0002" should have "link-0001" in links
    And ticket "link-0002" should have "link-0003" in links
    And ticket "link-0003" should have "link-0001" in links
    And ticket "link-0003" should have "link-0002" in links

  Scenario: Link is idempotent
    Given ticket "link-0001" is linked to "link-0002"
    When I run "ticket link link-0001 link-0002"
    Then the command should succeed
    And the output should be "All links already exist"

  Scenario: Unlink two tickets
    Given ticket "link-0001" is linked to "link-0002"
    When I run "ticket unlink link-0001 link-0002"
    Then the command should succeed
    And the output should be "Removed link: link-0001 <-> link-0002"
    And ticket "link-0001" should not have "link-0002" in links
    And ticket "link-0002" should not have "link-0001" in links

  Scenario: Unlink non-existent link
    When I run "ticket unlink link-0001 link-0002"
    Then the command should fail
    And the output should be "Link not found"

  Scenario: Unlink leaves links that contain its ID
    Given a ticket exists with ID "dt-fix" and title "Fix"
    And a ticket exists with ID "dt-fix-login" and title "Fix login"
    And ticket "link-0001" is linked to "dt-fix"
    And ticket "link-0001" is linked to "dt-fix-login"
    When I run "ticket unlink link-0001 dt-fix"
    Then the command should succeed
    And ticket "link-0001" should have field "links" with value "[dt-fix-login]"
    And ticket "dt-fix-login" should have "link-0001" in links
    And ticket "dt-fix" should not have "link-0001" in links

  Scenario: Unlink that only matches part of an existing link
    Given a ticket exists with ID "dt-fix" and title "Fix"
    And a ticket exists with ID "dt-fix-login" and title "Fix login"
    And ticket "link-0001" is linked to "dt-fix-login"
    When I run "ticket unlink link-0001 dt-fix"
    Then the command should fail
    And the output should be "Link not found"

  Scenario: Link with non-existent ticket
    When I run "ticket link link-0001 nonexistent"
    Then the command should fail
    And the output should contain "Error: ticket 'nonexistent' not found"

  Scenario: Partial linking adds only new links
    Given ticket "link-0001" is linked to "link-0002"
    When I run "ticket link link-0001 link-0002 link-0003"
    Then the command should succeed
    And the output should contain "Added 4 link(s) between 3 tickets"
