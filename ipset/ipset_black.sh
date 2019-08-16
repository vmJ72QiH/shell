#!/bin/bash
threshold=1000
FILES="/var/log/nginx/access.log"
TIME_SLOT=`date -d '1 minutes ago' +%Y:%H:%M`
grep ${TIME_SLOT} ${FILES} | awk  '{print $1}' | sort -n | uniq -c | sort -nr > /tmp/tempfile
awk '$1>'${threshold}'{print $2}' /tmp/tempfile > /tmp/blackiplist.txt
for i in `cat /tmp/blackiplist.txt`
do
/sbin/ipset -! add forbidip $i timeout 3600
done
#每天0点保存一次规则
currentHour=$(date +%H)
if [ $currentHour -eq 00 ]
then
    /sbin/ipset save > /etc/ipset.conf;
fi