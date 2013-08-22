# Nexus CLI
[![Build Status](https://travis-ci.org/RiotGames/nexus_cli.png)](https://travis-ci.org/RiotGames/nexus_cli)

A CLI wrapper around Sonatype Nexus REST calls.

# Requirements

* Ruby

# Installation

1. Install the Gem - `gem install nexus_cli`
2. Create a file in your user's home directory named `.nexus_cli`
3. Give the file the following information:

```
url: 			"http://my-nexus-server/nexus/"
repository:		"my-repository-id"
username: 		"username"
password: 		"password"
```

You can also omit the username and password to create an anonymous session with the Nexus server. Keep in mind that an anonymous session may have different permissions than an authenticated one, depending on your Nexus server configuration.

# Usage

There are a few calls that can be made. The most important are push\_artifact and pull\_artifact. Both calls will push or pull artifacts from Nexus using the Maven Co-ordinates syntax: `groupId:artifactId:version` (default extension is jar) or `groupId:artifactId:extension:version` or `groupId:artifactId:extension:classifier:version`

One can also search for artifacts and get back raw xml containing matches.

## Listing of Available Commands

```
nexus-cli add_to_group_repository group_id repository_to_add_id                # Adds a repository with the given id into the group repository.
nexus-cli add_trusted_key --certificate=CERTIFICATE --description=DESCRIPTION  # Adds a new trusted key to the Smart Proxy configuration.
nexus-cli change_password user_id                                              # Changes the given user's passwords to a new one.
nexus-cli clear_artifact_custom_info coordinates                               # Clears the artifact custom metadata.
nexus-cli create_group_repository name                                         # Creates a new repository group with the given name.
nexus-cli create_repository name                                               # Creates a new Repository with the provided name.
nexus-cli create_user                                                          # Creates a new user
nexus-cli delete_group_repository group_id                                     # Deletes a group repository based on the given id.
nexus-cli delete_repository name                                               # Deletes a Repository with the provided name.
nexus-cli delete_trusted_key key_id                                            # Deletes a trusted key using the given key_id.
nexus-cli delete_user user_id                                                  # Deletes the user with the given id.
nexus-cli disable_artifact_publish repository_id                               # Sets a repository to disable the publishing of updates about its artifacts.
nexus-cli disable_artifact_subscribe repository_id                             # Sets a repository to stop subscribing to updates about artifacts.
nexus-cli disable_smart_proxy                                                  # Disables Smart Proxy on the server.
nexus-cli enable_artifact_publish repository_id                                # Sets a repository to enable the publishing of updates about its artifacts.
nexus-cli enable_artifact_subscribe repository_id                              # Sets a repository to subscribe to updates about artifacts.
nexus-cli enable_smart_proxy                                                   # Enables Smart Proxy on the server.
nexus-cli get_artifact_custom_info coordinates                                 # Gets and returns the custom metadata in XML format about a particular artifact.
nexus-cli get_artifact_info coordinates                                        # Gets and returns the metadata in XML format about a particular artifact.
nexus-cli get_global_settings                                                  # Prints out your Nexus' current setttings and saves them to a file.
nexus-cli get_group_repository group_id                                        # Gets information about the given group repository.
nexus-cli get_license_info                                                     # Returns the license information of the server.
nexus-cli get_logging_info                                                     # Gets the log4j Settings of the Nexus server.
nexus-cli get_nexus_configuration                                              # Prints out configuration from the .nexus_cli file that helps inform where artifacts will be uploaded.
nexus-cli get_nexus_status                                                     # Prints out information about the Nexus instance.
nexus-cli get_pub_sub repository_id                                            # Returns the publish/subscribe status of the given repository.
nexus-cli get_repository_info name                                             # Finds and returns information about the provided Repository.
nexus-cli get_smart_proxy_settings                                             # Returns the Smart Proxy settings of the server.
nexus-cli get_trusted_keys                                                     # Returns the trusted keys of the server.
nexus-cli get_users                                                            # Returns XML representing the users in Nexus.
nexus-cli help [COMMAND]                                                       # Describe available commands or one specific command
nexus-cli install_license license_file                                         # Installs a license file into the server.
nexus-cli pull_artifact coordinates                                            # Pulls an artifact from Nexus and places it on your machine.
nexus-cli push_artifact coordinates file                                       # Pushes an artifact from your machine onto the Nexus.
nexus-cli remove_from_group_repository group_id repository_to_remove_id        # Remove a repository with the given id from the group repository.
nexus-cli reset_global_settings                                                # Resets your Nexus global_settings to their out-of-the-box defaults.
nexus-cli search_artifacts_custom param1 param2 ...                            # Searches for artifacts using artifact metadata and returns the result as a list with items in XML format.
nexus-cli search_for_artifacts                                                 # Searches for all the versions of a particular artifact and prints it to the screen.
nexus-cli set_logger_level level                                               # Updates the log4j logging level to a new value.
nexus-cli transfer_artifact coordinates from_repository to_repository          # Transfers a given artifact from one repository to another.
nexus-cli update_artifact_custom_info coordinates param1 param2 ...            # Updates the artifact custom metadata with the given key-value pairs.
nexus-cli update_user user_id                                                  # Updates a user's details. Leave fields blank for them to remain their current values.
nexus-cli upload_global_settings                                               # Uploads a global_settings.json file to your Nexus to update its settings.
```

Each command can be prefaced with `help` to get more information about the command. For example - `nexus-cli help get_users`

There are also two global config options, `--overrides` which overrides the configruation in `~/.nexus_cli` and `--ssl-verify false` which turns off SSL verification.

## Pull Artifact Example

```
nexus-cli pull_artifact com.mycompany.artifacts:myartifact:tgz:1.0.0
```

## Push Artifact Example

```
nexus-cli push_artifact com.mycompany.artifacts:myartifact:tgz:1.0.0 ~/path/to/file/to/push/myartifact.tgz
```

## Search Example

```
nexus-cli search_for_artifacts com.mycompany.artifacts:myartifact

or more generic if you wish:

nexus-cli search_for_artifacts com.mycompany.artifacts
```

# License and Author

Author:: Kyle Allan (<kallan@riotgames.com>)

Copyright:: 2013 Riot Games Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
