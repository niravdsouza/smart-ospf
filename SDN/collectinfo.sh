#!/bin/bash

p=`cat ./reference/configs.conf | grep p= | cut -d= -f2`
L=`cat ./reference/configs.conf | grep L= | cut -d= -f2`
n=`cat ./reference/configs.conf | grep n= | cut -d= -f2`
N=`cat ./reference/configs.conf | grep N= | cut -d= -f2`


# Iterate through all interfaces mentioned in the conf
for int in $(cat ./reference/configs.conf | grep interfaces= | cut -d= -f2 | sed 's/,/ /g')
do

	############################################################
	# Inserting new utilization value into historical database #
	############################################################

	current_rx=`ifconfig $int | grep bytes | awk '{print $2}' | cut -d: -f2`
	current_tx=`ifconfig $int | grep bytes | awk '{print $6}' | cut -d: -f2`

	if [ -f ./reference/previous_bytes.$int ]
	then
		previous_rx=`cat ./reference/previous_bytes.$int | grep RX | cut -d: -f2`
		previous_tx=`cat ./reference/previous_bytes.$int | grep TX | cut -d: -f2`
	else
		previous_rx=0
		previous_tx=0
	fi

	diff_rx=`expr $current_rx - $previous_rx`
	diff_tx=`expr $current_tx - $previous_tx`

	bandwidth=`cat ./reference/configs.conf | grep $int"_bandwidth" | cut -d= -f2`

	if [ $diff_rx -gt $diff_tx ]
	then
		utilization=`expr $diff_rx / $p / $bandwidth \* 100`
	else
		utilization=`expr $diff_tx / $p / $bandwidth \* 100`
	fi

	echo $utilization >> ./history/historicaldata.$int
	echo "RX:$current_rx" > ./reference/previous_bytes.$int
	echo "TX:$current_tx" >> ./reference/previous_bytes.$int

	###################################################
	# Calculating the utilization for the next period #
	###################################################

	count=`cat ./history/historicaldata.$int | wc -l`
	sum=0
	i=1
	num=0
	while [ $i -lt $count ]
	do
		val=`sed -n $i'p' ./history/historicaldata.$int`
		sum=`expr $sum + $val`
		i=`expr $i + $L`
		num=`expr $num + 1`
	done

	avg_utilization=`expr $sum / $num`

	# Delete first line if length is greater than required length
	if [ $count -gt $N ]
	then
		sed -i '1d' ./history/historicaldata.$int
	fi

	# Get the link cost from average utilization
	cat ./reference/linkcosts | while read line
	do
		lower=`echo $line | cut -d, -f1`
		upper=`echo $line | cut -d, -f2`
		if [[ $avg_utilization -ge $lower ]] && [[ $avg_utilization -le $upper ]]
		then
			tablecost=`echo $line | cut -d, -f3`
			multiplication_factor=`cat ./reference/configs.conf | grep $int"_multiplication_factor" | cut -d= -f2`
			linkcost=`expr $tablecost \* $multiplication_factor`
			break
		fi
	done

done



