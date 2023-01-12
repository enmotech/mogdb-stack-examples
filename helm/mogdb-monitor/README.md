# mogdb-monitor

**Keep helm version >= 3.2**

## 添加仓库

```shell
helm repo add mogdb-chart https://enmotech.github.io/mogdb-stack-helm-charts
```

## 更新仓库

```shell
helm repo update mogdb-chart
```

## 安装

### 全命令行参数安装

```shell
helm install monitor \
 --set alertEmailHost='smtp.exmail.qq.com' \
 --set alertEmailSmtp='smtp.exmail.qq.com:465' 
 --set alertEmailUsername='xxx@xxx.com' 
 --set alertEmailPassword='<密码>' 
 --set receiversEmail='xxxx@qq.com' 
 mogdb-chart/mogdb-monitor --namespace monitoring --create-namespace
```

首次安装没有 monitoring 命名空间添加 `--create-namespace`

### 添加配置文件安装

添加配置文件 myvalues.yaml

```yaml
# 邮箱预警配置
alertEmailHost: smtp.163.com # 告警邮箱server host
alertEmailSmtp: smtp.163.com:25 # 发送邮件的SMTP server，包括端口号
alertEmailUsername: xxxx@163.com # 发送告警的邮箱
alertEmailPassword: <邮箱密码> # 邮箱授权密码

receiversEmail: xxx@qq.com  # 接收报警的邮箱，多个用逗号隔开
```

修改对应的配置，执行
  ```shell
  helm install -f myvalues.yaml monitor mogdb-chart/mogdb-monitor
  ``` 

## 查看

主机ip:<grafana端口> 查看grafana图形化界面
主机ip:<prometheus端口> 查看prometheus图形化界面
主机ip:<alertmanager端口> 查看alertmanager图形化界面

## 更新

```shell
helm upgrade monitor \
 --set alertEmailHost='smtp.exmail.qq.com' \
 --set alertEmailSmtp='smtp.exmail.qq.com:465' 
 --set alertEmailUsername='xxx@xxx.com' 
 --set alertEmailPassword='<密码>' 
 --set receiversEmail='xxxx@qq.com\,xxxx@qq.com'
 mogdb-chart/mogdb-monitor
```

配置多个接收邮箱用 ```\,``` 隔开，更新配置之后等待十几秒（Pod 同步间隔时间，默认10秒），调用alertmanager重新加载配置接口
```
curl -XPOST 主机ip:<alertmanager端口>/-/reload 
```

访问 ```主机ip:<alertmanager端口>/#/status``` ，查看配置是否更新




