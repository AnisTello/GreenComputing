#! /bin/bash

filename="$1"
tmp=${filename:0:-4}
newfile=${tmp}_modified
var=0
touch $newfile
while read -r line
do
	substring=${line:98:-3}
	echo -e "$var $substring" >> $newfile
	var=$((var+100))
done < "$filename"
