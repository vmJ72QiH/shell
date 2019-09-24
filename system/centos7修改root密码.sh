#centos7 修改root密码
#https://blog.csdn.net/wudinaniya/article/details/81060536
#重启系统，在开机过程中，快速按下键盘上的方向键和。目的是告知引导程序，我们需要在引导页面选择不同的操作，以便让引导程序暂停。
#按键盘 e 键，进入编辑模式，找到 linux16 的那一行。将光标一直移动到最后面，空格，再追加 init=/bin/sh。这里特别注意要保持再同一行，并注意空格。由于屏幕太小，会自动添加\换行，这个是正常的。

#按下Ctrl+X 进行引导启动(单用户模式启动)，成功后进入该界面。然后输入以下命令

mount -o remount, rw /
passwd root
# 输入2次一样的新密码，注意输入密码的时候屏幕上不会有字符出现。

更新系统信息
touch /.autorelabel

#最后重启系统
exec /sbin/init 
或
exec /sbin/reboot
