#!/bin/bash
export PATH=$PATH:/bin/:/sbin:/usr/sbin  

echo "config yum repo."
cd /etc/yum.repos.d/
wget -q -o /dev/null http://mirrors.aliyun.com/repo/Centos-7.repo
wget -q -o /dev/null http://mirrors.aliyun.com/repo/epel-7.repo
\cp Centos-7.repo CentOS-Base.repo 
\mv epel-7.repo epel.repo 
rm -rf Centos-7.repo 
    

echo "sysstat ntp net-snmp lrzsz rsync"
yum -y install sysstat ntp net-snmp lrzsz rsync vim openssh-clients net-tools > /dev/null 2>&1    

echo "#close selinux iptables"
cp /etc/selinux/config /etc/selinux/config.$(date +%y%m%d)
/etc/init.d/iptables stop
sed -i 's/SELINUX=enable/SELINUX=disabled/g'  /etc/selinux/config
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g'  /etc/selinux/config
setenforce 0
grep SELINUX=disabled /etc/selinux/config

Systemctl stop firewalld
Systemctl disable firewalld

sleep 1 

echo "---------sshconfig ---------#"
\cp /etc/ssh/sshd_config /etc/ssh/sshd_config.$(date +%y%m%d)
sed -i 's/#UseDNS yes/UseDNS yes/' /etc/ssh/sshd_config
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config

echo "---------open files--------------"
\cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%y%m%d)

sed -i 's/1024/unlimited/g' /etc/security/limits.d/90-nproc.conf

cat >> /etc/security/limits.conf << EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF

cat >> /etc/sysctl.conf  << EOF
net.ipv4. tcp_timestamps = 0  
net.ipv4. tcp_synack_retries = 2
net.ipv4. tcp_syn_retries = 2
net.ipv4. tcp_mem = 9450000 915000000 927000000
net.ipv4. tcp_max_orphans = 3276800
net.core.wmem_default = 8388608
net.core. rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 1677216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.ip_local_port_range = 1024  65535
EOF
cat >> /etc/profile  << EOF
export PS1="\n\e[1;37m[\e[m\e[1;35m\u\e[m\e[1;36m@\e[m\e[1;37m\H\e[m \e[1;33m\A\e[m \w\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\\\\$ "
export GREP_OPTIONS='--color=auto'
ulimit -u 65535
ulimit -n 65535
EOF
