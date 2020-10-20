#!/bin/sh

if [ $# -lt 1 ];then
	echo "lack of  sleep time"
	exit 1
else
	time=$1
fi

led=user

while [ 1 ]
do
echo 1 > /sys/class/leds/${led}/brightness
sleep $time
echo 0 > /sys/class/leds/${led}/brightness
sleep $time

done

