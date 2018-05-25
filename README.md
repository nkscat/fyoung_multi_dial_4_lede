# 目标
网速叠加
# 依赖
1. [fchiannet](https://github.com/01Sr/fchinanet)
2. [mwan3](https://acris.me/2017/06/25/Load-balancing-multiple-PPPoE-on-LEDE/#more)
# 原理
1. fchinanet
2. openwrt环境下，配置了mwan3，流量优先通过metric小的interface
3. 通过uci命令动态改变metric，之后对不同的interface逐个认证，达到一台路由登录多个设备的效果
# 提醒
1. 该shell一定不可能导入设备便可运行成功，需要根据实际情况定制，具体阅读代码和注释
2. 该shell语法不保证所有环境都可运行，在搞懂逻辑的情况下可能仍需1天时间让其在你的设备正常运行
3. 非openwrt/基于op固件不要尝试
4. 完全没玩过路由刷机可能要一周时间使其正常运行。有基础的使用者可能要花半天时，慎入
