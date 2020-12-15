@ECHO OFF
SET tooling_jar=tooling-1.3.1-SNAPSHOT-jar-with-dependencies.jar
SET input_cache_path=%~dp0input-cache
SET ig_resource_path=input/htnu18ig.xml
SET resources_path=%~dp0input/resources

ECHO Checking internet connection...
PING tx.fhir.org -n 1 -w 1000 | FINDSTR TTL && GOTO isonline
ECHO We're offline...
SET fsoption=
GOTO igpublish

:isonline
ECHO We're online, setting publish to local sandbox FHIR server
SET fsoption=-fs http://localhost:8080/cqf-ruler-r4/fhir/

:igpublish

SET JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8

IF EXIST "%input_cache_path%\%tooling_jar%" (
	ECHO running: JAVA -jar "%input_cache_path%\%tooling_jar%" -RefreshIG -root-dir=%~dp0 -ip="%ig_resource_path%" -rp="%resources_path%" -t -d -p -cdsig %fsoption%
	JAVA -jar "%input_cache_path%\%tooling_jar%" -RefreshIG -root-dir=%~dp0 -ip="%ig_resource_path%" -rp="%resources_path%" -t -d -p -cdsig %fsoption%
) ELSE If exist "..\%tooling_jar%" (
	ECHO running: JAVA -jar "..\%tooling_jar%" -RefreshIG -root-dir=%~dp0 -ip="%ig_resource_path%" -rp="%resources_path%" -t -d -p -cdsig %fsoption%
	JAVA -jar "..\%tooling_jar%" -RefreshIG -root-dir=%~dp0 -ip="%ig_resource_path%" -rp="%resources_path%" -t -d -p -cdsig %fsoption%
) ELSE (
	ECHO IG Refresh NOT FOUND in input-cache or parent folder.  Please run _updateCQFTooling.  Aborting...
)

PAUSE
