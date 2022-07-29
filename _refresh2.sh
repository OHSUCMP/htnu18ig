#!/bin/bash
#DO NOT EDIT WITH WINDOWS
# This is the refresh script that should be run for CQF Ruler 0.5.0 - it uses a newer tooling jar and no context path
tooling_jar=tooling-1.4.0-jar-with-dependencies.jar
input_cache_path=$PWD/input-cache
resources_path=$PWD/input/resources
ig_ini_path=$PWD/ig.ini

set -e
echo Checking internet connection...
wget -q --spider tx.fhir.org

if [ $? -eq 0 ]; then
echo "Online"
fsoption="http://localhost:8080/fhir/"
else
echo "Offline"
fsoption=""
fi

echo "$fsoption"

tooling=$input_cache_path/$tooling_jar
if test -f "$tooling"; then
JAVA -jar $tooling -RefreshIG -ini="$ig_ini_path" -rp="$resources_path" -t -d -p $fsoption
else
tooling=../$tooling_jar
echo $tooling
if test -f "$tooling"; then
JAVA -jar $tooling -RefreshIG -ini="$ig_ini_path" -rp="$resources_path" -t -d -p $fsoption
else
echo IG Refresh NOT FOUND in input-cache or parent folder. Please run _updateCQFTooling. Aborting...
fi
fi
