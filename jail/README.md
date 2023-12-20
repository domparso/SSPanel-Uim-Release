# jail


### 
检测当前iptables来验证禁止规则
iptables --list -n

fail2ban-client start/stop/restart/reload/ping

检验fail2ban状态
fail2ban-client status <JAIL>

特定监狱的状态
fail2ban-client status ssh-iptables

添加/解锁特定的IP地址
fail2ban-client set <JAIL> banip/unbanip <IP>

添加/解除指定 IP 的忽略
fail2ban-client set <JAIL> addignoreip/delignoreip <IP>

测试匹配规则
fail2ban-r7egex <日志文件> <过滤规则>

启动打印
/usr/bin/fail2ban-client -v -v start
