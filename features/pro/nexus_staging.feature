Feature: Use the Nexus CLI to execute commands that interact with the Nexus Pro Staging Suite
  As a Pro CLI user
  I need commands to start, close, and release Nexus Staging Repositories

  Scenario: Start a Staging Repository
    When I call the nexus "start_staging" command
    Then the output should contain:
    """
    rcs-005
    """
    And the exit status should be 0