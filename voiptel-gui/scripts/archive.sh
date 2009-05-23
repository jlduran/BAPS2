#!/bin/sh 

src=$1
dst=$2

ls $dst > /dev/null 2>&1

if [ $? -eq 0 ]
then
cnt=0
exists=1
while [ $exists -eq 1 ]
do
ls $dst.$cnt > /dev/null 2>&1
if [ $? -eq 1 ]
then
mv $src $dst.$cnt
exists=0
else
cnt=`expr $cnt + 1`
fi
done
else
mv $src $dst
fi
touch $src

