#!/bin/bash
#定时清除elk索引，10天
DATE=$(date -d "10 days ago" +%Y.%m.%d)
echo $DATE
#localhost为es服务运行绑定IP
curl -X DELETE "localhost:9200/*-${DATE}"