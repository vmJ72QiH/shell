#!/bin/bash
FILES="/var/log/nginx/access.log"
TIME_SLOT=`date -d '1 minutes ago' +%Y:%H:%M`
grep ${TIME_SLOT} ${FILES} | awk  '{print $1}' | sort -n | uniq -c | sort -nr | head -1 > /tmp/blackiplist
NUM=`awk '{print $1}' /tmp/ips`
threshold=1000
if [[ $NUM -gt $threshold ]];then
/sbin/ipset -! add forbidip $IP timeout 3600
fi
for i in $IP2
do
/sbin/ipset -! add forbidip $i
done
#每天保存一次规则