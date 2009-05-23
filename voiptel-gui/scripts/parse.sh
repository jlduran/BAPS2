#!/bin/sh 

filename=$1 
year=$2
month=$3
day=$4

#sed '/^"",/d' $filename > /tmp/x 
sed '/executecommand/d' $filename > /tmp/x 
#sed 's/",/"@@/g' /tmp/x > /tmp/y 
sed 's/,/@@/g' /tmp/x > /tmp/y 
sed 's/"//g' /tmp/y > /tmp/x 

#cat /tmp/y | awk -F@@ '{printf ("%-30s %-12s %-22s %-22s %-8s \n", $1,$2,$9,$11,$12)}' > /tmp/x 
#cat /tmp/y | awk -F@@ '{printf ("%s,%s,%s,%s,%s,%s,%s<BREAK>\n", $1,$2,$3,$4,$5,$6,$7)}' | tr -d '\"' > /tmp/x
cat /tmp/y | awk -F@@ '{printf ("%s,%s,%s,%s,%s,%s,%s<BREAK>\n", $5,$3,$10,$11,$12,$14,$15)}' | tr -d '\"' > /tmp/x

#cat -n /tmp/x > /tmp/y

if [ $year != "" ] && [ $month != "" ] && [ $day != "" ]
then
grep -e $year'-'$month'-'$day /tmp/x > /tmp/y
#grep -e '2007-01-01' /tmp/x > /tmp/y
mv /tmp/y /tmp/x
fi

#temp fix - remove garbage from Master.csv:
cat $filename | sed '/executecommand/d' > /tmp/Master.csv
mv /tmp/Master.csv $filename

cat /tmp/x
rm /tmp/x
#echo $year; echo $month; echo $day
