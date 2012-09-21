Feature: Use the Nexus Pro CLI
	As a Pro CLI user
	I need commands to get, update, search, and delete Nexus artifact custom metadata
		
  Scenario: Push an artifact
    When I push an artifact with the GAV of "com.test:myprotest:1.0.0:tgz"
    Then the output should contain:
	    """
	    Artifact com.test:myprotest:1.0.0:tgz has been successfully pushed to Nexus.
	    """
    And the exit status should be 0

	Scenario: Update an artifact's custom metadata
		When I call the nexus "update_artifact_custom_info com.test:myprotest:1.0.0:tgz somekey:somevalue" command
		Then the output should contain:
			"""
			Custom metadata for artifact com.test:myprotest:1.0.0:tgz has been successfully pushed to Nexus.
			"""
		And the exit status should be 0

	Scenario: Update an artifact's custom metadata with multiple parameters
		When I call the nexus "update_artifact_custom_info com.test:myprotest:1.0.0:tgz somekey:somevalue_1! \"someotherkey:some other value\" tempkey:tempvalue" command
		Then the output should contain:
			"""
			Custom metadata for artifact com.test:myprotest:1.0.0:tgz has been successfully pushed to Nexus.
			"""
		And the exit status should be 0
		
	Scenario: Update an artifact's custom metadata and remove a key
		When I call the nexus "update_artifact_custom_info com.test:myprotest:1.0.0:tgz tempkey:" command
		Then the output should contain:
			"""
			Custom metadata for artifact com.test:myprotest:1.0.0:tgz has been successfully pushed to Nexus.
			"""
		And the exit status should be 0

	Scenario: Get an artifact's custom metadata
		When I call the nexus "custom com.test:myprotest:1.0.0:tgz" command
		Then the output should contain:
			"""
			<somekey>somevalue_1!</somekey>
			"""
		And the output should contain:
			"""
			<someotherkey>some other value</someotherkey>
			"""
		And the exit status should be 0

	Scenario: Search for artifacts by custom metadata using matches
		When I call the nexus "search_custom somekey:matches:*value*" command
		Then the output should contain:
			"""
			<artifactId>myprotest</artifactId>
			"""
		And the exit status should be 0

	Scenario: Search for artifacts by custom metadata using equal
		When I call the nexus "search_custom somekey:equal:somevalue_1!" command
		Then the output should contain:
			"""
			<artifactId>myprotest</artifactId>
			"""
		And the exit status should be 0

	Scenario: Search for artifacts by custom metadata using multiple parameters
		When I call the nexus "search_custom somekey:matches:*value* somekey:equal:somevalue_1!" command
		Then the output should contain:
			"""
			<artifactId>myprotest</artifactId>
			"""
		And the exit status should be 0

	Scenario: Search for artifacts by custom metadata that return an empty result set
		When I call the nexus "search_custom fakekey:equal:fakevalue" command
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