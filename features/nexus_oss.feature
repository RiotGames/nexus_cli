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
  
  @pull
  Scenario: Pull an artifact
    When I call the nexus "pull com.test:mytest:1.0.0:tgz" command
    Then the output should contain:
      """
      Artifact has been retrieved and can be found at path:
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

  @transfer
  Scenario: Transfer an artifact between repositories
    When I call the nexus "transfer com.test:mytest:1.0.0:tgz releases thirdparty" command
    Then the output should contain:
      """
      The artifact com.test:mytest:1.0.0:tgz has been transferred from releases to thirdparty.
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

  @delete
  Scenario: Attempt to delete another artifact
    When I delete an artifact with the GAV of "com.test:mytest:1.0.0:tgz" from the "thirdparty" repository
    And I call the nexus "info com.test:mytest:1.0.0:tgz" command overriding "repository:thirdparty"
    Then the output should contain:
      """
      The artifact you requested information for could not be found. Please ensure it exists inside the Nexus.
      """
    And the exit status should be 101


  Scenario: Get the current global settings of Nexus
    When I call the nexus "get_global_settings" command
    Then the output should contain:
      """
      Your current Nexus global settings have been written to the file: ~/.nexus/global_settings.json
      """
    And a file named "global_settings.json" should exist in my nexus folder
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
    Then the file "global_settings.json" in my nexus folder should contain:
      """
      "forceBaseUrl": true
      """
    And the exit status should be 0
  
  Scenario: Update the global settings of Nexus with a string
    When I update global settings uiTimeout to 61 and upload the json string
    And I call the nexus "get_global_settings" command
    Then the file "global_settings.json" in my nexus folder should contain:
    """
    "uiTimeout": 61
    """
    And the exit status should be 0

  Scenario: Reset the global settings of Nexus
    When I call the nexus "reset_global_settings" command
    Then the output should contain:
      """
      Your Nexus global settings have been reset to their default values
      """
    When I call the nexus "get_global_settings" command
    Then the file "global_settings.json" in my nexus folder should contain:
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
      The repository you provided could not be found. Please ensure the repository exists.
      """
    And the exit status should be 114

  Scenario: Create a new user
    When I call the nexus "create_user --username=cucumber --first_name=John --last_name=Smith --email=jsmith@nexus-cli.com --enabled --roles=nx-admin --password=pass" command
    And I call the nexus "get_users" command
    Then the output should contain:
      """
      <userId>cucumber</userId>
      """
    And the exit status should be 0

  Scenario: Change a users information
    When I call the nexus "update_user cucumber --first_name=Mike --last_name=Ditka --email= --enabled --roles=" command
    And I call the nexus "get_users" command
    Then the output should contain:
      """
      <lastName>Ditka</lastName>
      """
    And the exit status should be 0

  Scenario: Change a users password
    When I call the nexus "change_password cucumber --oldPassword=pass --newPassword=foo" command
    And I call the nexus "get_users" command as the "cucumber" user with password "wrongPassword"
    Then the output should contain:
      """
      Your request was denied by the Nexus server due to a permissions error
      """
    And the exit status should be 106

  Scenario: Delete a user
    When I call the nexus "delete_user cucumber" command
    And I call the nexus "get_users" command
    Then the output should not contain:
      """
      <userId>cucumber</userId>
      """
    And the exit status should be 0

  Scenario: Get Logging Info
    When I call the nexus "get_logging_info" command
    Then the output should contain:
      """
      \"rootLoggerLevel\":\"INFO\"
      """
    And the exit status should be 0

  Scenario: Change the logging level to DEBUG
    When I call the nexus "set_logger_level debug" command
    And I call the nexus "get_logging_info" command
    Then the output should contain:
      """
      \"rootLoggerLevel\":\"DEBUG\"
      """
    And the exit status should be 0

  Scenario: Change the logging level back to INFO
    When I call the nexus "set_logger_level info" command
    Then the output should contain:
      """
      The logging level of Nexus has been set to INFO
      """
    And the exit status should be 0

  Scenario: Create a Nexus Group Repository
    When I call the nexus "create_group_repository cucumber_group" command
    Then the output should contain:
      """
      A new group repository named cucumber_group has been created.
      """
    And the exit status should be 0

  Scenario: Get information about a Nexus Group Repository
    When I call the nexus "get_group_repository cucumber_group" command
    Then the output should contain:
      """
      \"id\":\"cucumber_group\"
      """
    And the exit status should be 0

  Scenario: Add a repository to the Nexus Group Repository
    When I call the nexus "add_to_group_repository cucumber_group releases" command
    Then the output should contain:
      """
      The repository releases has been added to the repository group cucumber_group
      """
    And the exit status should be 0

  Scenario: Remove a repository from a Nexus Group Repository
    When I call the nexus "remove_from_group_repository cucumber_group releases" command
    And I call the nexus "get_group_repository cucumber_group" command
    Then the output should not contain:
     """
     \"id\"=>\"releases\"
     """
    And the exit status should be 0

  Scenario: Delete a Nexus Group Repository
    When I call the nexus "delete_group_repository cucumber_group" command
    And I call the nexus "get_group_repository cucumber_group" command
    Then the output should not contain:
      """
      \"id\":\"cucumber_group\"
      """
    And the exit status should be 114