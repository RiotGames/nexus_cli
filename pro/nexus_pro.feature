Feature: Use the Nexus Pro CLI
	As a Pro CLI user
	I need commands to get, update, search, and delete Nexus artifact custom metadata

	Scenario: Get Nexus Pro Status
		When I call the nexus "status" command
		Then the output should contain:
			"""
			Application Name: Sonatype Nexus Professional
			"""
		And the exit status should be 0

  @push
  Scenario: Push an artifact
    When I push an artifact with the GAV of "com.test:myprotest:1.0.0:tgz"
    Then the output should contain:
	    """
	    Artifact com.test:myprotest:1.0.0:tgz has been successfully pushed to Nexus.
	    """
    And the exit status should be 0

	Scenario: Update an artifact's custom metadata
		When I call the nexus "update_artifact_custom_info com.test:myprotest:1.0.0:tgz teemoHat:equipped" command
		Then the output should contain:
			"""
			Custom metadata for artifact com.test:myprotest:1.0.0:tgz has been successfully pushed to Nexus.
			"""
		And the exit status should be 0

	Scenario: Update an artifact's custom metadata with multiple parameters
		When I call the nexus "update_artifact_custom_info com.test:myprotest:1.0.0:tgz teemoHat:equipped_ \"teemoSkins:many skins!!1\"" command
		Then the output should contain:
			"""
			Custom metadata for artifact com.test:myprotest:1.0.0:tgz has been successfully pushed to Nexus.
			"""
		And the exit status should be 0

	Scenario: Get an artifact's custom metadata
		When I call the nexus "custom com.test:myprotest:1.0.0:tgz" command
		Then the output should contain:
			"""
			<teemoHat>equipped_</teemoHat>
			"""
		And the output should contain:
			"""
			<teemoSkins>many skins!!1</teemoSkins>
			"""
		And the exit status should be 0

	Scenario: Get an artifact's raw custom metadata
		When I call the nexus "custom_raw com.test:myprotest:1.0.0:tgz" command
		Then the output should contain:
			"""
			<urn:nexus/user#teemoHat> "equipped_"
			"""
		And the output should contain:
			"""
			<urn:nexus/user#teemoSkins> "many skins!!1"
			"""
		And the exit status should be 0

	Scenario: Search for artifacts by custom metadata using matches
		When I call the nexus "search_custom teemoHat:matches:equip*" command
		Then the output should contain:
			"""
			<artifactId>myprotest</artifactId>
			"""
		And the exit status should be 0

	Scenario: Search for artifacts by custom metadata using equal
		When I call the nexus "search_custom teemoHat:equal:equipped_" command
		Then the output should contain:
			"""
			<artifactId>myprotest</artifactId>
			"""
		And the exit status should be 0

	Scenario: Search for artifacts by custom metadata using multiple parameters
		When I call the nexus "search_custom teemoHat:matches:equip* teemoHat:equal:equipped_" command
		Then the output should contain:
			"""
			<artifactId>myprotest</artifactId>
			"""
		And the exit status should be 0

	Scenario: Search for artifacts by custom metadata that return an empty result set
		When I call the nexus "search_custom bestTeemo:equal:malady" command
		Then the output should contain:
			"""
			No search results.
			"""
		And the exit status should be 0

	Scenario: Clear an artifact's custom metadata
		When I call the nexus "clear_artifact_custom_info com.test:myprotest:1.0.0:tgz" command
		Then the output should contain:
			"""
			Custom metadata for artifact com.test:myprotest:1.0.0:tgz has been successfully cleared.
			"""
		And the exit status should be 0

  @delete
  Scenario: Attempt to delete an artifact
    When I delete an artifact with the GAV of "com.test:myprotest:1.0.0:tgz"
    And I call the nexus "info com.test:myprotest:1.0.0:tgz" command
    Then the output should contain:
	    """
	    The artifact you requested information for could not be found. Please ensure it exists inside the Nexus.
	    """
    And the exit status should be 101