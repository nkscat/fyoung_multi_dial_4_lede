# 参考
[MWAN3配置](https://acris.me/2017/06/25/Load-balancing-multiple-PPPoE-on-LEDE/#more)
# 目标
网速叠加
# 方法
1. 新建虚拟网卡并设置开机自启
```
ip link add link eth0.2 name veth0 type macvlan;
ifconfig veth0 up;
```
2. 新建接口并设置相应metric
```
config interface 'KGFAN'
	option ifname 'veth0'
	option proto 'dhcp'
	option macaddr 'C0:EE:FB:FF:E7:1C'
	option metric '41'
```
3. MWAN3配置
- 接口
>名称和etc/config/network相同，其他默认
- 成员
>名称随意，添加相应接口，其他默认
- 策略
>balanced中添加所有成员
- 规则
>使用默认规则
# 交流
QQ群：[695837323](https://jq.qq.com/?_wv=1027&k=5d6Y4EC)
