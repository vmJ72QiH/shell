#yum安装7.3.1ELK
#E L K 所有组件放在一台
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat>/etc/yum.repos.d/elk.repo<<EOF
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

for i in elasticsearch logstash kibana iptables-services java-latest-openjdk.x86_64 nginx;do yum install -y $i;done

cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.bak
cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.bak
cp /etc/logstash/logstash.yml /etc/logstash/logstash.yml.bak

#安装htpasswd
yum install -y httpd-tools 
htpasswd -cm /etc/nginx/htpasswd user
#密码
# 

cat>/etc/kibana/kibana.yml<<EOF
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://172.31.178.53:9200"]
i18n.locale: "zh-CN"
EOF
cat>/etc/elasticsearch/elasticsearch.yml<<EOF
cluster.name: es.cluster
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 172.31.178.53
http.port: 9200
discovery.seed_hosts: ["172.31.178.53"]
cluster.initial_master_nodes: ["172.31.178.53"]
EOF
cat>/etc/logstash/logstash.yml<<EOF
node.name: localhost
path.data: /var/lib/logstash
path.logs: /var/log/logstash
config.reload.automatic: true
config.reload.interval: 10s
http.host: "0.0.0.0"
EOF
cat>/etc/logstash/conf.d/nginx.conf<<EOF
input {
  beats {
    port => "13838"
    codec => json
  }
}

output {
    elasticsearch {
       hosts =>["172.31.178.53:9200"]
       index =>"nginx-log-%{+YYYY.MM.dd}"
    }
}
EOF



#启动命令
/etc/init.d/elasticsearch start
/etc/init.d/kibana start
/etc/init.d/kibana stop
/etc/init.d/elasticsearch stop
systemctl start logstash
systemctl stop logstash



#出现Logstash.service: Unit not found  
#/usr/share/logstash/bin/system-install /etc/logstash/startup.options systemd


#/etc/nginx/nginx.conf 主要配置
#禁止IP访问
    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        return 403;
    }

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  www.domain.com domain.com;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;
#登陆验证 反向代理
        location / {
		proxy_pass http://172.31.178.53:5601$request_uri;
		auth_basic	"登陆验证";
		auth_basic_user_file /etc/nginx/htpasswd;
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
-----------------------------------------------------------------------------
#节点日志格式
log_format log_json '{ "time_local": "$time_local", '
	'"remote_addr": "$remote_addr", '
	'"referer": "$http_referer", '
	'"request": "$request", '
	'"httprequest": "$http_referer", '
	'"status": $status, '
	'"bytes": $body_bytes_sent, '
	'"agent": "$http_user_agent", '
	'"x_forwarded": "$http_x_forwarded_for", '
	'"up_addr": "$upstream_addr",'
	'"up_host": "$upstream_http_host",'
	'"up_resp_time": "$upstream_response_time",'
	'"request_time": "$request_time"'
	' }';
将access 日志格式改为  log_json
nginx -t
nginx -s reload
#检查日志格式是否生效
tail -f /var/log/nginx/access.log
#centos6 修改主机名
vi /etc/sysconfig/network
HOSTNAME=aaa

hostname aaa
#检测hostname
hostname
#hosts文件与主机名修改无关,仅为解析使用  一般不用改有特殊需要可以改

#在节点上安装filebeat
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.2.3-linux-x86_64.tar.gz
sleep 1
tar xf filebeat-6.2.3-linux-x86_64.tar.gz -C /usr/local/
sleep 1
cd /usr/local/filebeat-6.2.3-linux-x86_64/
cp filebeat.yml filebeat.yml.bak
sleep 1
cat>/usr/local/filebeat-6.2.3-linux-x86_64/filebeat.yml<<EOF
filebeat.prospectors:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/*.log
filebeat.config.modules:
  path: \${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 3
setup.kibana:
output.logstash:
  hosts: ["ip:port"]
EOF

sleep 1
#启动命令
nohup ./filebeat -e -c filebeat.yml &
ps -ef | grep filebeat



----------------------------扩展  添加map需要的logstash配置
#新版本自带geo插件
input {
  beats {
    port => "5044"
    codec => json
  }
}
filter {
  geoip {
    source => "remote_addr"
    target => "geoip"
    add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
    add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}" ]
  }
  mutate {
    convert => [ "[geoip][coordinates]", "float"]
       }
}

output {
    elasticsearch {
       hosts =>["192.168.176.139:9200"]
       index =>"logstash-nginx-log-%{+YYYY.MM.dd}"
    }
}
--------------------------------------------------------------------------