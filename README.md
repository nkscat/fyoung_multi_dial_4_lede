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
1. 该shell不可能导入设备就运行成功，需要根据实际情况定制，具体阅读代码和注释
2. 该shell语法不保证所有环境都可运行，在搞懂逻辑的情况下可能仍需1天时间在调试语法
3. 仅仅支持openwrt/基于op的固件
4. 完全没折腾过路由刷机可能要一周时间使其正常运行。有经验的使用者可能也要一下午，慎入
# 目录
```
usr
│   
└───fchinanet
    │   README.md  ---  说明文件
    │   start.sh   ---  认证逻辑
    |   core       ---  fchinanet核心认证程序，根据路由CPU架构更换
    |   date       ---  日期记录文件，为本人实际使用场景所需，具体阅读代码，可删除相应逻辑
    |   log        ---  日志记录
    |   exit       ---  退出文件，文件内容可为任意值，默认是0
```
