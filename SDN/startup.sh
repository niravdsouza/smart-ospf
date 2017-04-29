#!/bin/bash

N=`cat ./reference/configs.conf | grep N= | cut -d= -f2`

#if [ -f ./reference/previous_bytes.* ]
#then
#	rm ./reference/previous_bytes.*
#fi

#if [ -f ./history/historicaldata.* ]
#then
#	rm ./history/historicaldata.*
#fi

for int in $(cat ./reference/configs.conf | grep interfaces= | cut -d= -f2 | sed 's/,/ /g')
do
	current_rx=`ifconfig $int | grep bytes | awk '{print $2}' | cut -d: -f2`
	current_tx=`ifconfig $int | grep bytes | awk '{print $6}' | cut -d: -f2`

	echo "RX:$current_rx" > ./reference/previous_bytes.$int
	echo "TX:$current_tx" >> ./reference/previous_bytes.$int

	> ./history/historicaldata.$int
	for i in $(seq 1 $N)
	do
		echo 0 >> ./history/historicaldata.$int
	done
done

