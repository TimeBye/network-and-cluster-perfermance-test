#!/bin/bash

if [ x$1 == 'x' ]; then
    echo "Too few arguments"
    exit 1
else 
	curl --fail -o /dev/null -s ${1}
	if [ $? != 0 ]; then
		echo "Could not resolve host: ${1}"
		exit 1
	fi
fi

item=1
echo -e "No\ttime_connect\ttime_starttransfer\ttime_total"
while(( $item<=${2:-10} ))
do
    curl -o /dev/null -s -w "${item}\t%{time_connect}\t%{time_starttransfer}\t\t%{time_total}\n" ${1}
    let item+=1
done