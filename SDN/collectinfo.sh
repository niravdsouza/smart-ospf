#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

SDN_path=/root/smart-ospf/SDN
#ospf_config_file=/etc/quagga/zebra.conf

p=`cat $SDN_path/reference/configs.conf | grep p= | cut -d= -f2`
L=`cat $SDN_path/reference/configs.conf | grep L= | cut -d= -f2`
n=`cat $SDN_path/reference/configs.conf | grep n= | cut -d= -f2`
N=`cat $SDN_path/reference/configs.conf | grep N= | cut -d= -f2`

date >> $SDN_path/linkcost.log

# Iterate through all interfaces mentioned in the conf
for int in $(cat $SDN_path/reference/configs.conf | grep interfaces= | cut -d= -f2 | sed 's/,/ /g')
do

	############################################################
	# Inserting new utilization value into historical database #
	############################################################

	echo "For interface $int" >> $SDN_path/linkcost.log
	
	current_rx=`ifconfig $int | grep bytes | awk '{print $2}' | cut -d: -f2`
	current_tx=`ifconfig $int | grep bytes | awk '{print $6}' | cut -d: -f2`
	echo "Current RX: "$current_rx >> $SDN_path/linkcost.log
	echo "Current TX: $current_tx" >> $SDN_path/linkcost.log
	if [ -f $SDN_path/reference/previous_bytes.$int ]
	then
		previous_rx=`cat $SDN_path/reference/previous_bytes.$int | grep RX | cut -d: -f2`
		previous_tx=`cat $SDN_path/reference/previous_bytes.$int | grep TX | cut -d: -f2`

	else
		previous_rx=0
		previous_tx=0
	fi
	echo "Previous RX: $previous_rx" >> $SDN_path/linkcost.log
	echo "Previous TX: $previous_tx" >> $SDN_path/linkcost.log

	diff_rx=`expr $current_rx - $previous_rx`
	diff_tx=`expr $current_tx - $previous_tx`
	echo "Diff RX: $diff_rx" >> $SDN_path/linkcost.log
	echo "Diff TX: $diff_tx" >> $SDN_path/linkcost.log

	bandwidth=`cat $SDN_path/reference/configs.conf | grep $int"_bandwidth" | cut -d= -f2`
	echo "Bandwidth: $bandwidth" >> $SDN_path/linkcost.log

	if [ $diff_rx -gt $diff_tx ]
	then
		echo "RX > TX" >> $SDN_path/linkcost.log
		utilization=`expr $diff_rx \* 100 / $p / $bandwidth`
	else
		echo "TX > RX" >> $SDN_path/linkcost.log
		echo "p=$p" >> $SDN_path/linkcost.log
		echo "Temp 1=`expr $diff_tx \* 100 / $p / $bandwidth`" >> $SDN_path/linkcost.log
		echo "Temp 2=`expr $bandwidth \* 100`" >> $SDN_path/linkcost.log
		utilization=`expr $diff_tx \* 100 / $p / $bandwidth`
	fi
	if [ $utilization -gt 100 ]
	then
		utilization=100
	fi
	echo "Utilization: $utilization" >> $SDN_path/linkcost.log

	echo $utilization >> $SDN_path/history/historicaldata.$int
	echo "RX:$current_rx" > $SDN_path/reference/previous_bytes.$int
	echo "TX:$current_tx" >> $SDN_path/reference/previous_bytes.$int

	###################################################
	# Calculating the utilization for the next period #
	###################################################

	count=`cat $SDN_path/history/historicaldata.$int | wc -l`
	sum=0
	i=1
	num=0
	while [ $i -lt $count ]
	do
		val=`sed -n $i'p' $SDN_path/history/historicaldata.$int`
		sum=`expr $sum + $val`
		i=`expr $i + $L`
		num=`expr $num + 1`
	done

	avg_utilization=`expr $sum / $num`
	echo "Average utilization: $avg_utilization" >> $SDN_path/linkcost.log

	# Delete first line if length is greater than required length
	if [ $count -gt $N ]
	then
		sed -i '1d' $SDN_path/history/historicaldata.$int
	fi

	# Get the link cost from average utilization
	sed '1d' $SDN_path/reference/linkcosts | while read line
	do
		lower=`echo $line | cut -d, -f1`
		upper=`echo $line | cut -d, -f2`
		if [ $avg_utilization -ge $lower ]
		then
			if [ $avg_utilization -le $upper ]
			then
				tablecost=`echo $line | cut -d, -f3`
				multiplication_factor=`cat $SDN_path/reference/configs.conf | grep $int"_multiplication_factor" | cut -d= -f2`
				linkcost=`expr $tablecost \* $multiplication_factor`
				echo "Linkcost: $linkcost" >> $SDN_path/linkcost.log
				(echo "zebra"; echo "en"; sleep 0.000001; echo "conf t"; sleep 0.000001; echo "int $int";sleep 0.000001;echo "ip ospf cost $linkcost"; sleep 0.000001; echo "quit" ) | telnet localhost 2604
				break
			fi
		fi
	done

done

# Running OSPF
#echo "Running OSPF" >> $SDN_path/linkcost.log
#/etc/init.d/quagga restart


