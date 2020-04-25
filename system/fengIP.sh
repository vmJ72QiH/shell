#!/bin/bash
#IP存放文件
echo "" > /root/2.txt

#格式化时间与nginx默认的时间格式对应
oneagotime=$(date -d "1 minutes ago" +%d/%b/%Y:%H:%M)

#获取IP
blackip=`cat /var/log/nginx/access.log | grep "关键字" | awk '{split($3,a,"\"");if(a[2]>="'$oneagotime'"){print $0}}' | awk -F ":" '{print $6}' | awk -F "," '{print $1}' | sort | uniq -c| sort -nr | sed 's/\"//g' |  awk -F" "  '{if ($1>20)print $2}'`

for i in $blackip
do
        aaa=`cat /etc/nginx/conf.d/deny.conf | grep $i`
        if [ -z "$aaa" ];then
                echo $i >> /root/2.txt
        fi

done