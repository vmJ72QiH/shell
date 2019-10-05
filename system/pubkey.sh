#!/bin/bash
#yum安装expect
yum -y install expect
#PWD_1是登陆密码，可以自己设定
PASSWORD=111111
#这是你的集群内的主机名，需要先修改host文件
hosts="192.168.176.150"
key_generate() {
    expect -c "set timeout -1;
        spawn ssh-keygen -t rsa;
        expect {
            {Enter file in which to save the key*} {send -- \r;exp_continue}
            {Enter passphrase*} {send -- \r;exp_continue}
            {Enter same passphrase again:} {send -- \r;exp_continue}
            {Overwrite (y/n)*} {send -- n\r;exp_continue}
            eof             {exit 0;}
    };"
}
auto_ssh_copy_id () {
    expect -c "set timeout -1;
        spawn ssh-copy-id -i $HOME/.ssh/id_rsa.pub root@$1;
            expect {
                {Are you sure you want to continue connecting *} {send -- yes\r;exp_continue;}
                {*password:} {send -- $2\r;exp_continue;}
                eof {exit 0;}
            };"
}

key_generate

for host in $hosts
do
    auto_ssh_copy_id $host  $PASSWORD
done
