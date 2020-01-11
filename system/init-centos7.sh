#!/bin/bash
export PATH=$PATH:/bin/:/sbin:/usr/sbin  
yum_repo() {
echo "config yum repo."
cd /etc/yum.repos.d/
wget -q -o /dev/null http://mirrors.aliyun.com/repo/Centos-7.repo
wget -q -o /dev/null http://mirrors.aliyun.com/repo/epel-7.repo
\cp Centos-7.repo CentOS-Base.repo 
\mv epel-7.repo epel.repo 
rm -rf Centos-7.repo 
}    

# echo "---------sshconfig ---------#"
# \cp /etc/ssh/sshd_config /etc/ssh/sshd_config.$(date +%y%m%d)
# sed -i 's/#UseDNS yes/UseDNS yes/' /etc/ssh/sshd_config
# sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config

# echo "---------open files--------------"
# \cp /etc/security/limits.conf /etc/security/limits.conf.$(date +%y%m%d)
# sed -i 's/1024/unlimited/g' /etc/security/limits.d/90-nproc.conf

packages_install() {
for i in bash-completion-extras bash-completion epel-release sysstat pcre-devel net-snmp zlib zlib-devel rsync openssl perl gcc net-tools bind-utils iftop bind-utils iptables-services net-tools vim wget psmisc;do yum -y install $i ;done
}

selinux_set() {
cp /etc/selinux/config /etc/selinux/config.$(date +%y%m%d)
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
}

iptables_set() {
systemctl enable iptables.service
systemctl stop firewalld
systemctl disable firewalld
sed -i '/:OUTPUT ACCEPT/a-A INPUT -s IP -p tcp -m state --state NEW -m tcp --dport 11111 -j ACCEPT' /etc/sysconfig/iptables
systemctl restart iptables.service
}

sshd_set() {
sed -i 's/#Port 22/Port 11111/' /etc/ssh/sshd_config
systemctl restart sshd
}

limits_set() {
a=`sed -n '/* hard nofile 65535/p' /etc/security/limits.conf`
if [ ! "$a" ]; then
cat >> /etc/security/limits.conf << EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
fi
}

sysctl_set() {
a=`sed -n '/net.ipv4.tcp_mem = 9450000 915000000 927000000/p' /etc/sysctl.conf`
if [ ! "$a" ]; then
cat >> /etc/sysctl.conf  << EOF
net.ipv4.tcp_timestamps = 0  
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_mem = 9450000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
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
fi
}

profile_set() {
a=`sed -n '/ulimit -n 65535/p' /etc/profile`
if [ ! "$a" ]; then
cat >> /etc/profile  << EOF
export PS1="\n\e[1;37m[\e[m\e[1;35m\u\e[m\e[1;36m@\e[m\e[1;37m\h\e[m \e[1;33m\A\e[m \e[1;31m\w\e[m\e[m\e[1;37m]\e[m\e[1;36m\e[m\n\\\\$ "
ulimit -u 65535
ulimit -n 65535
EOF
fi
}

# swap_set() {
# #dd if=/dev/zero of=/usr/sbin/swapfile bs=1M count=4096 物理机配置
# #yun peizi
# dd if=/dev/zero of=/usr/sbin/swapfile bs=1M count=8000
# mkswap /usr/sbin/swapfile
# swapon /usr/sbin/swapfile
# cat >> /etc/fstab << EOFI
# /usr/sbin/swapfile swap swap defaults 0 0
# EOFI
# }

ipv6_set() {
sed -i 's/GRUB_CMDLINE_LINUX=\"/&\"ipv6.disable=1\" /' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
}


yum_repo
packages_install
selinux_set
iptables_set
limits_set
sysctl_set
profile_set
sshd_set
ipv6_set
#重置变量a
unset a