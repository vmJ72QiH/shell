#!/bin/bash
#按IP访问频率封IP
echo "" > /root/1.txt
blocktime=$(date -d "1 minute ago" "+%Y:%H:%M")
blockip=$(grep $blocktime /var/log/nginx/access.log | grep "\ag" |awk -F ":" '{print $6}' | awk -F "," '{print $1}'| sed 's/\"//g' | sort | uniq -c| sort -nr |  awk -F" "  '{if ($1>1000)print $2}')
if [ -z $blockip ];then
        exit
fi
for i in $blockip
do
        aaa=`cat /etc/nginx/conf.d/deny.conf | grep $i`
        if [ -z "$aaa" ];then
                echo $i >> /root/1.txt
        fi

done
/bin/sh /root/deny.sh
#deny.sh 内容
#for i in `cat /root/1.txt`
#do
#echo "deny $i;" >> /etc/nginx/conf.d/deny.conf
#done
#/etc/init.d/nginx reload
