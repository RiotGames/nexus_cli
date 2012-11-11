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

  Scenario: Set a repository to publish updates
    When I call the nexus "enable_artifact_publish releases" command
    And I call the nexus "get_pub_sub releases" command
    Then the output should contain:
    	"""
    	<publish>true</publish>
    	"""
    And the exit status should be 0

  Scenario: Set a repository to not publish updates
    When I call the nexus "disable_artifact_publish releases" command
    And I call the nexus "get_pub_sub releases" command
    Then the output should contain:
    	"""
    	<publish>false</publish>
    	"""
    And the exit status should be 0

  Scenario: Set a repository to subscribe to updates
  	When I call the nexus "enable_artifact_subscribe central" command
  	And I call the nexus "get_pub_sub central" command
  	Then the output should contain:
  		"""
  		<subscribe>true</subscribe>
  		"""
  	And the exit status should be 0

  Scenario: Set a repository to not subscribe to updates
  	When I call the nexus "disable_artifact_subscribe central" command
  	And I call the nexus "get_pub_sub central" command
  	Then the output should contain:
  		"""
  		<subscribe>false</subscribe>
  		"""
  	And the exit status should be 0

  Scenario: Enable Smart Proxy on the Server
    When I call the nexus "enable_smart_proxy" command
    And I call the nexus "get_smart_proxy_settings" command
    Then the output should contain:
      """
      "enabled": true
      """
    And the exit status should be 0

  Scenario: Enable Smart Proxy and set the host
    When I call the nexus "enable_smart_proxy --host=0.0.0.1" command
    And I call the nexus "get_smart_proxy_settings" command
    Then the output should contain:
      """
      "host": "0.0.0.1"
      """
    And the exit status should be 0

  Scenario: Enable Smart Proxy and set the host
    When I call the nexus "enable_smart_proxy --port=1234" command
    And I call the nexus "get_smart_proxy_settings" command
    Then the output should contain:
      """
      "port": 1234
      """
    And the exit status should be 0

  Scenario: Disable Smart Proxy on the Server
    When I call the nexus "disable_smart_proxy" command
    And I call the nexus "get_smart_proxy_settings" command
    Then the output should contain:
      """
      "enabled": false
      """
    And the exit status should be 0

  Scenario: Add a trusted key
    When I add a trusted key to nexus
    And I call the nexus "get_trusted_keys" command
    Then the output should contain:
      """
      cucumber
      """
    And the exit status should be 0
  
  Scenario: Delete a trusted key
    When I delete a trusted key in nexus
    And I call the nexus "get_trusted_keys" command
    Then the output should not contain:
      """
      cucumber
      """
    And the exit status should be 0