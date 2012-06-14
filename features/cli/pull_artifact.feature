@cli
Feature: Pull Artifact
  As a CLI user
  I need a command to pull artifacts from the Nexus repository
  So I have a way to get artifacts from a remote system to my local machine

  Scenario: Pull an artifact
    When I get the artifact "com.riotgames.tar:mytar:1.0.3:tgz"
    Then I should have a copy of the "mytar-1.0.3.tgz" artifact on my computer

  Scenario: Pull an artifact to a specific place
    When I want the artifact "com.riotgames.tar:mytar:1.0.3:tgz" in a temp directory
    Then I should have a copy of the "mytar-1.0.3.tgz" artifact in a temp directory

  Scenario: Attempt to pull an artifact with the wrong parameters
    When I run `nexus-cli pull_artifact com.riotgames.whatever:something`
    Then I should expect an error because I need more colon separated values