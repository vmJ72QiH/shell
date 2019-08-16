#!/bin/bash
#时间格式化
BEGINTIME=`date +"%Y-%m-%d %H:%M:%S"`
format_time=`date +"%Y-%m-%d_%H:%M:%S"`
week=`date +%Y-%m-%d`

#backupbin:innobackuppex绝对位置，
#backdir:备份目录
#redun:冗余目录，存放上一周的数据压缩包(上上一周的会被此脚本删除)
#file_cnf:mysql配置文件绝对路径 socket:mysql.sock文件绝对路径 
#out_log:日志输出位置   ， time_cost:一周内的备份记录时间轴

backupbin=/usr/bin
backdir=/database/detect/backup
redun=/database/detect/redundency
file_cnf=/etc/my.cnf
#用户需要进mysql授权
#grant reload,lock tables,replication client,create tablespace,process,super on *.* to 自己设置@'localhost' identified by '自己设置';
#FLUSH   PRIVILEGES;
user_name=自己设置
password="自己设置"
socket="/var/lib/mysql/mysql.sock"
out_log=$backdir/xtrabackup_log_$format_time
time_cost=$backdir/xtrabackup_time.txt

#创建数据存放目录1
if [ ! -d "/database/detect/redundency" ];
then 
mkdir -p /database/detect/redundency
fi
#创建数据存放目录2
if [ ! -d "/database/detect/backup" ];
then 
mkdir -p /database/detect/backup
fi

#判断是否为一周轮转，是则打包上周的数据 并删除上上周的压缩包
if [ -d "$backdir/incr5" ];then
tar -czvf ${redun}/redundency_${week}.tar.gz -C /database/detect/ backup >/dev/null 2>&1
echo "删除 $backdir/* 操作 "
rm -rf $backdir/*
mkdir -p $backdir
chown -R mysql.mysql $backdir
# del backup
DEL_UNTIL_DATE=`date --date='7 day ago' +%Y-%m-%d`
 
sleep 30
/bin/rm -f /${redun}/*${DEL_UNTIL_DATE}.tar.gz >/dev/null 2>&1
 
fi 
 
#第一个if为全备，elif都是以上一次备份数据为节点的增备
if [ ! -d "$backdir/full" ];then
echo "#####start full backup at $BEGINTIME to directory full" >>$time_cost
$backupbin/innobackupex --defaults-file=$file_cnf --no-timestamp --user=$user_name --password=$password --socket=$socket  $backdir/full 1> $out_log 2>&1
break;
elif [ ! -d "$backdir/incr0" ];then
echo "#####start 0 incremental backup at $BEGINTIME to directory incr0" >>$time_cost
$backupbin/innobackupex --defaults-file=$file_cnf  --no-timestamp --user=$user_name --password=$password --socket=$socket --incremental --incremental-basedir=$backdir/full $backdir/incr0 1> $out_log 2>&1
break;
elif [ ! -d "$backdir/incr1" ];then
echo "#####start 1 incremental backup at $BEGINTIME to directory incr1" >>$time_cost
$backupbin/innobackupex --defaults-file=$file_cnf  --no-timestamp --user=$user_name --password=$password --socket=$socket  --incremental --incremental-basedir=$backdir/incr0 $backdir/incr1 1> $out_log 2>&1
break;
elif [ ! -d "$backdir/incr2" ];then
echo "#####start 2 incremental backup at $BEGINTIME to directory incr2" >>$time_cost
$backupbin/innobackupex --defaults-file=$file_cnf  --no-timestamp --user=$user_name --password=$password --socket=$socket  --incremental --incremental-basedir=$backdir/incr1 $backdir/incr2 1> $out_log 2>&1
break;
elif [ ! -d "$backdir/incr3" ];then
echo "#####start 3 incremental backup at $BEGINTIME to directory incr3" >>$time_cost
$backupbin/innobackupex --defaults-file=$file_cnf  --no-timestamp --user=$user_name --password=$password --socket=$socket  --incremental --incremental-basedir=$backdir/incr2 $backdir/incr3 1> $out_log 2>&1
break;
elif [ ! -d "$backdir/incr4" ];then
echo "#####start 4 incremental backup at $BEGINTIME to directory incr4" >>$time_cost
$backupbin/innobackupex --defaults-file=$file_cnf  --no-timestamp --user=$user_name --password=$password --socket=$socket  --incremental --incremental-basedir=$backdir/incr3 $backdir/incr4 1> $out_log 2>&1
break;
elif [ ! -d "$backdir/incr5" ];then
echo "#####start 5 incremental backup at $BEGINTIME to directory incr5" >>$time_cost
$backupbin/innobackupex --defaults-file=$file_cnf  --no-timestamp --user=$user_name --password=$password --socket=$socket  --incremental --incremental-basedir=$backdir/incr4 $backdir/incr5 1> $out_log 2>&1
break;
fi
ENDTIME=`date +"%Y-%m-%d %H:%M:%S"`
begin_data=`date -d "$BEGINTIME" +%s`
end_data=`date -d "$ENDTIME" +%s`
spendtime=`expr $end_data - $begin_data`
echo "it takes $spendtime sec for packing the data directory" >>$time_cost
