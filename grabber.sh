#!/bin/bash

# An utility script to grab source files
#
# example:
# grabber.sh src/*.vala
# grabber.sh src/*.vala vapi/*.vapi

array=()

for pattern in $@; do
	for filename in $pattern; do
		array+=("$filename")
	done
done

length=${#array[@]}
idx=0
for filename in "${array[@]}"; do
	idx=$((idx + 1))
	if [ $idx -eq $length ]; then
		echo "'$filename'"
	else
		echo "'$filename',"
	fi
done
