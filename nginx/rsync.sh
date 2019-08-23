#!bin/bash
#rsync免密传输要先做单向免密
#serverlist.txt写服务器IP
function nginx_restart(){
ssh $i "/usr/sbin/nginx -t && systemctl restart nginx"
if [ $? !=  0 ];then
        echo -e "\033[1;31m\t\t $i nginx 未重启\033[0m"
else
        echo -e "\033[1;32m\t\t$i nginx 重启成功\033[0m"
fi
}
for i in `cat serverlist.txt`
do
rsync -avz /etc/nginx/ $i:/etc/nginx/
nginx_restart
done