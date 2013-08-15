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

# Usage

There are a few calls that can be made. The most important are push\_artifact and pull\_artifact. Both calls will push or pull artifacts from Nexus using the Maven Co-ordinates syntax: `groupId:artifactId:version` or `groupId:artifactId:extension:version` or `groupId:artifactId:extension:classifier:version`

One can also search for artifacts and get back raw xml containing matches.

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

Copyright:: 2012 Riot Games Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
