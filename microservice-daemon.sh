#!/bin/bash

if [ $4 == "" ]; then
	echo "USAGE: $1 <job name> <jar file> <port> [java main arguments]"
	exit 1
fi

ACK_URL=http://lsymms-dev.no-ip.org:$3
JOB_NAME=$1
JENKINS_HOME=/var/lib/jenkins
JAVA_ARGS="--server.port=$3 --hostname=lsymms-dev.no-ip.org $4"
JAR_FILE=$2
JAVA_BIN=$JENKINS_HOME/tools/hudson.model.JDK/7/bin/java
OUTPUT_FILE=/var/log/jenkins/$JOB_NAME.out
PID_FILE=/var/run/jenkins/$JOB_NAME.pid
echo starting microservice: $JOB_NAME
echo residing at: $JAR_FILE
echo using args: $JAVA_ARGS

daemon --running --name=$JOB_NAME --pidfile=$PID_FILE
if [ $? -eq 0 ]; then
	printf "$JOB_NAME is running. Shutting down"
	echo "---------------- STOP SERVER SIGNALED ------------------" >> $OUTPUT_FILE
	daemon --stop --name=$JOB_NAME --pidfile=$PID_FILE
	while daemon --running --name=$JOB_NAME --pidfile=$PID_FILE 
	do
		printf ". "
		sleep 0.1
	done
	echo	
	echo $JOB_NAME stopped
fi	
echo $JOB_NAME not running. Starting...
echo "---------------- STARTING SERVER ------------------" >> $OUTPUT_FILE
daemon --name=$JOB_NAME --inherit --output=$OUTPUT_FILE --pidfile=$PID_FILE -- $JAVA_BIN -jar $JAR_FILE $JAVA_ARGS

# Verify that the server starts by getting a
for (( i=0; i<60; i++ )) 
do
	wget -SO- -T 5 -t 1 $ACK_URL
        WGET_EXIT_CD=$? 
        echo exit code: $WGET_EXIT_CD   
        if [ $WGET_EXIT_CD -eq 0 ]; then
		echo Server started succesfully
		exit 0
	fi
	sleep 1
done

echo Timeout waiting for server to start

echo tail of server log:
tail -1000 $OUTPUT_FILE

exit 1	
