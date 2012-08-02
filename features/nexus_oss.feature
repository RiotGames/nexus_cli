Feature: Use the Nexus CLI
  As a CLI user
  I need commands to get Nexus status, push, pull
  
  Scenario: Get Nexus Status
    When I call the nexus "status" command
    Then the output should contain:
      """
      Application Name: Sonatype Nexus
      Version: 2.0.5
      """
    And the exit status should be 0

  @push
  Scenario: Push an Artifact
    When I push an artifact with the GAV of "com.test:mytest:1.0.0:tgz"
    Then the output should contain:
      """
      Artifact com.test:mytest:1.0.0:tgz has been successfully pushed to Nexus.
      """
    And the exit status should be 0
  
  Scenario: Pull an artifact
    When I call the nexus "pull com.test:mytest:1.0.0:tgz" command
    Then the output should contain:
    """
    Artifact has been retrived and can be found at path:
    """
    And the exit status should be 0

  Scenario: Pull the LATEST of an artifact
    When I pull an artifact with the GAV of "com.test:mytest:latest:tgz" to a temp directory
    Then I should have a copy of the "mytest-1.0.0.tgz" artifact in a temp directory
    And the exit status should be 0
  
  Scenario: Pull an artifact to a specific place
    When I pull an artifact with the GAV of "com.test:mytest:1.0.0:tgz" to a temp directory
    Then I should have a copy of the "mytest-1.0.0.tgz" artifact in a temp directory
    And the exit status should be 0

  Scenario: Get an artifact's info
    When I call the nexus "info com.test:mytest:1.0.0:tgz" command
    Then the output should contain:
    """
    <groupId>com.test</groupId>
    """
    And the exit status should be 0

  Scenario: Search for artifacts
    When I call the nexus "search_for_artifacts com.test:mytest" command
    Then the output should contain:
    """
    Found Versions:
    1.0.0:    `nexus-cli pull com.test:mytest:1.0.0:tgz`
    """
    And the exit status should be 0

  @delete
  Scenario: Attempt to delete an artifact
    When I delete an artifact with the GAV of "com.test:mytest:1.0.0:tgz"
    And I call the nexus "info com.test:mytest:1.0.0:tgz" command
    Then the output should contain:
    """
    The artifact you requested information for could not be found. Please ensure it exists inside the Nexus.
    """
    And the exit status should be 101