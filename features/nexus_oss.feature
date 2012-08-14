Feature: Use the Nexus CLI
  As a CLI user
  I need commands to get Nexus status, push, pull
  
  Scenario: Get Nexus Status
    When I call the nexus "status" command
    Then the output should contain:
      """
      Application Name: Sonatype Nexus
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

  Scenario: Get the current global settings of Nexus
    When I call the nexus "get_global_settings" command
    Then the output should contain:
      """
      Your current Nexus global settings have been written to the file: global_settings.json
      """
    And a file named "global_settings.json" should exist
    And the exit status should be 0

  Scenario: Update the global settings of Nexus
    When I call the nexus "get_global_settings" command
    And I edit the "global_settings.json" files "forceBaseUrl" field to true
    And I call the nexus "upload_global_settings" command
    Then the output should contain:
      """
      Your global_settings.json file has been uploaded to Nexus
      """
    When I call the nexus "get_global_settings" command
    Then the file "global_settings.json" should contain:
      """
      "forceBaseUrl": true
      """
    And the exit status should be 0

  Scenario: Reset the global settings of Nexus
    When I call the nexus "reset_global_settings" command
    Then the output should contain:
      """
      Your Nexus global settings have been reset to their default values
      """
    When I call the nexus "get_global_settings" command
    Then the file "global_settings.json" should contain:
      """
      "forceBaseUrl": false
      """
    And the exit status should be 0

  Scenario: Create a new repository in Nexus
    When I call the nexus "create_repository Artifacts" command
    Then the output should contain:
      """
      A new Repository named Artifacts has been created.
      """
    And the exit status should be 0

  Scenario: Delete a repository in Nexus
    When I call the nexus "delete_repository Artifacts" command
    And I call the nexus "get_repository_info Artifacts" command
    Then the output should contain:
      """
      The repository you requested information could not be found. Please ensure the repository exists.
      """
    And the exit status should be 114
    