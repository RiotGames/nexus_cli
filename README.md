Description
===========

A CLI wrapper around Sonatype Nexus REST calls.

Requirements
============

* Ruby

Installation
============

1. Install the Gem
2. Create a file in your user's home directory named `.nexus_cli`
3. Give the file the following information:

```
url: 			"http://my-nexus-server/nexus/"
repository:		"my-repository-id"
username: 		"username"
password: 		"password"
```

Usage
=====

There are two calls that can be made. push\_artifact and pull\_artifact. Both calls will push or pull artifacts from Nexus using the Maven-flavored syntax: `groupId:artifactId:version:extension`

Pull Artifact Example
---------------------
```
nexus-cli pull_artifact com.mycompany.artifacts:myartifact:1.0.0:tgz
```
Push Artifact Example
---------------------
```
nexus-cli push_artifact com.mycompany.artifacts:myartifact:1.0.0:tgz ~/path/to/file/to/push/myartifact.tgz
```

License and Author
==================

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