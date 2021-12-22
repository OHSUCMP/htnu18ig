@ECHO OFF

ECHO ========
ECHO = HACK =
ECHO ========
ECHO Due to FireEye Endpoint Security antivirus scanner (an OHSU thing) identifying 
ECHO the original batch file as malicious, I've had to modify this script such that 
ECHO it can still exist and provide some degree of utility.
ECHO.
ECHO So now, you must manually download the following file and store it into the
ECHO input-cache/ folder.  This file can't be stored in the GitHub repo as it's too
ECHO large, which would have been a good solution but whatever, gotta work around
ECHO technical limitations.
ECHO.
ECHO Dumb.  Whatever.
ECHO.
ECHO "https://oss.sonatype.org/service/local/artifact/maven/redirect?r=snapshots&g=org.opencds.cqf&a=tooling&v=1.3.1-SNAPSHOT&c=jar-with-dependencies"
ECHO.
