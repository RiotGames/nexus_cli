Feature: Push Artifact
  As a CLI User
  I need a command to push artifacts into the Nexus repository
  So I have a way to get artifacts from Nexus when I want them

  Scenario: Push an Artifact
    When I push an artifact into the Nexus
    Then I should be able to ask the Nexus for information about it and get a result
