#!/bin/bash
mkdir -p /etc/zabbix/scripts
cat >/etc/zabbix/scripts/nginx_monitor.sh<<EOF
#!/bin/bash
NGINX_COMMAND=\$1
function alive {
alive=\`/usr/bin/curl -s "http://localhost/nginx_status" 2> /dev/null| grep 'Active' | awk '{print \$NF}'\`
if [ -z \${alive} ];
then
echo 0
else
echo 1
fi
}
nginx_active(){
    /usr/bin/curl -s "http://localhost/nginx_status/" |awk '/Active/ {print \$NF}'
}
nginx_reading(){
    /usr/bin/curl -s "http://localhost/nginx_status/" |awk '/Reading/ {print \$2}'
}
nginx_writing(){
    /usr/bin/curl -s "http://localhost/nginx_status/" |awk '/Writing/ {print \$4}'
       }
nginx_waiting(){
    /usr/bin/curl -s "http://localhost/nginx_status/" |awk '/Waiting/ {print \$6}'
       }
nginx_accepts(){
    /usr/bin/curl -s "http://localhost/nginx_status/" |awk 'NR==3 {print \$1}'
       }
nginx_handled(){
    /usr/bin/curl -s "http://localhost/nginx_status/" |awk 'NR==3 {print \$2}'
       }
nginx_requests(){
    /usr/bin/curl -s "http://localhost/nginx_status/" |awk 'NR==3 {print \$3}'
       }
  case \$NGINX_COMMAND in
active)
nginx_active;
;;
reading)
nginx_reading;
;;
writing)
nginx_writing;
;;
waiting)
nginx_waiting;
;;
accepts)
nginx_accepts;
;;
handled)
nginx_handled;
;;
alive)
alive;
;;
requests)
nginx_requests;
;;
      *)
echo \$"USAGE:\$0 {active|reading|writing|waiting|accepts|handled|requests}"
    esac
EOF
#---------------------
chmod a+x /etc/zabbix/scripts/nginx_monitor.sh
NGINX_STATUS=`grep "nginx_status" /etc/nginx/conf.d/default.conf`
if [ -z "$NGINX_STATUS" ];then
	sed -i '/#error_page/i\    location \/nginx_status {' /etc/nginx/conf.d/default.conf
	sed -i '/#error_page/i\        stub_status on;' /etc/nginx/conf.d/default.conf
	sed -i '/#error_page/i\        access_log off;' /etc/nginx/conf.d/default.conf
	sed -i '/#error_page/i\        allow 127.0.0.1;' /etc/nginx/conf.d/default.conf
	sed -i '/#error_page/i\        allow 152.101.131.150;' /etc/nginx/conf.d/default.conf
	sed -i '/#error_page/i\        deny all;' /etc/nginx/conf.d/default.conf
	sed -i '/#error_page/i\    }' /etc/nginx/conf.d/default.conf
fi
NGINX_INCLUDE=`grep "include /etc/nginx/conf.d/default.conf" /etc/nginx/nginx.conf`
INCLUDE_NUM=`grep -n "}" /etc/nginx/nginx.conf| tail -1 | awk -F ":" '{print $1}'`
if [ -z "$NGINX_INCLUDE" ];then
	sed -i "$INCLUDE_NUM i \    include /etc/nginx/conf.d/default.conf;" /etc/nginx/nginx.conf
fi
ZABBIX_NGINX=`grep "UserParameter=nginx_status" /etc/zabbix/zabbix_agentd.conf`
if [ -z "$ZABBIX_NGINX" ];then
	sed -i '$a UserParameter=nginx_status[*],/bin/bash /etc/zabbix/scripts/nginx_monitor.sh "$1"' /etc/zabbix/zabbix_agentd.conf
fi
nginx -t
if [ $? == 0 ];then
	nginx -s reload
else
	exit
fi
sleep 2
alivetest=`curl -s "http://localhost/nginx_status" 2> /dev/null| grep 'Active' | awk '{print $NF}'`
if [ -n ${alivetest} ];then
	/etc/init.d/zabbix-agent restart
fi
