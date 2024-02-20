#!/bin/bash
#DO NOT EDIT WITH WINDOWS
#exit 1

v=1.4.3

dlurl='https://oss.sonatype.org/service/local/repo_groups/public/content/org/opencds/cqf/tooling/'${v}'/tooling-'${v}'-jar-with-dependencies.jar'
tooling_jar='tooling-'${v}'-jar-with-dependencies.jar'

echo ${dlurl}

input_cache_path=./input-cache/

set -e
if ! type "wget" > /dev/null; then
	echo "ERROR: Script needs wget to download latest IG Tooling. Please install wget."
	exit 1
fi

jarlocation="$input_cache_path$tooling_jar"
echo Will place tooling jar here: $jarlocation
message="Ok? [Y/N]"

read -r -p "$message" response
if [[ "$response" =~ ^([yY])$ ]]; then
	wget -O "${jarlocation}" "${dlurl}"
	echo "Download complete."
else
	echo cancel...
fi
