# MogDB Stack安装

## 第1步: 安装MogDB Operator

部署MogDB Operator的过程分为两步:

1. 安装MogDB Operator CRDs

2. 安装MogDB Operator

### 安装MogDB Operator CRDs

MogDB Operator包含许多自定义的资源类型(CRDs)。执行以下命令安装CRD到Kubernetes集群中:

```shell
kubectl apply -f https://raw.githubusercontent.com/enmotech/mogdb-stack-examples/main/helm/crd.yaml
```

期望输出:

```text
customresourcedefinition.apiextensions.k8s.io/mogdbclusters.mogdb.enmotech.io created
customresourcedefinition.apiextensions.k8s.io/mogdbbackups.mogdb.enmotech.io created
```

### 安装MogDB Operator

安装[Helm 3](https://helm.sh/docs/intro/install/)并使用Helm 3部署MogDB Operator

1. 添加MogDB Stack仓库

    ```shell
    helm repo add mogdb-stack https://enmotech.github.io/mogdb-stack-examples/helm/charts
    ```

    期望输出:

    ```text
    "mogdb-stack" has been added to your repositories
    ```

2. 为MogDB Operator创建一个命名空间

    ```shell
    kubectl create namespace mogdb-operator-system
    ```

    期望输出:

    ```text
    namespace/mogdb-operator-system created
    ```

3. 安装MogDB Operator

    ```shell
    helm install myproject mogdb-stack/mogdb-operator --namespace mogdb-operator-system
    ```
   
    期望输出:

    ```text
    NAME: myproject
    LAST DEPLOYED: Tue Jan 10 17:33:05 2023
    NAMESPACE: mogdb-operator-system
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    Thank you for deploying a MogDB Operator!
    ```

检查MogDB Operator组建是否正常运行起来:

```shell
kubectl get pods -n mogdb-operator-system
```

期望输出:

```text
NAME                                       READY   STATUS    RESTARTS   AGE
mogdb-operator-myproject-5cd5bb9d9-7xztz   1/1     Running   0          73s
```

当pod处于Running状态时，继续下一步。

## 第2步: 安装MogDB apiserver

```shell
helm install myapiserver helm/mogdb-apiserver --namespace mogdb-operator-system
```

期望输出:

```text
NAME: myapiserver
LAST DEPLOYED: Tue Jan 10 17:43:50 2023
NAMESPACE: mogdb-operator-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying a MogDB Operator Apiserver!
```

检查MogDB apiserver正常运行起来:

```shell
NAME                                       READY   STATUS    RESTARTS   AGE
mogdb-apiserver-699c855d9b-878qj           1/1     Running   0          72s
mogdb-operator-myproject-5cd5bb9d9-7xztz   1/1     Running   0          11m
```

当pod处于Running状态时，继续下一步。

## 第3步: 安装Mogha

1. 为Mogha创建一个命名空间

    ```shell
    kubectl create namespace mogha
    ```
    
    期望输出:
    
    ```text
    namespace/mogha created
    ```

2. 安装Mogha

    ```shell
    helm install mogdb-ha helm/mogha --namespace mogha
    ```
    
    期望输出:
    
    ```text
    NAME: mogdb-ha
    LAST DEPLOYED: Tue Jan 10 17:40:51 2023
    NAMESPACE: mogha
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    Thank you for deploying a Mogha!
    ```

检查Mogha组建是否运行正常:

```shell
kubectl get pods -n mogha
```

期望输出:

```text
NAME                        READY   STATUS    RESTARTS   AGE
mogdb-ha-6d67c96476-6j42z   2/2     Running   0          49s
```

当pod处于Running状态时，继续下一步。

## 第4步: 安装监控与告警

1. 配置

    ```shell
    cat > myvalues.yaml <<-EOF
    grafanaNodeport: 31043 # grafana 图形界面地址端口
    prometheusNodeport: 31042 # prometheus 图形界面地址端口
    alertmanagerNodeport: 31044 # alertmanager 图形界面地址端口
    
    alertEmailHost: smtp.163.com # 告警邮箱server host
    alertEmailSmtp: smtp.163.com:25 # 发送邮件的SMTP server，包括端口号
    alertEmailUsername: <Your Email Name> # 发送告警的邮箱
    alertEmailPassword: <Your Email Password> # 邮箱授权密码
    receiversEmail: <Your Receive Email>  # 接收报警的邮箱，多个用逗号隔开
    EOF
    ```

2. 为监控创建一个命名空间

    ```shell
    kubectl create namespace monitor
    ```

   期望输出:

    ```text
    namespace/monitor created
    ```

3. 安装监控与告警

    ```shell
    helm install -f myvalues.yaml monitor helm/mogdb-monitor --namespace monitor
    ```

    期望输出:

    ```text
    NAME: monitor
    LAST DEPLOYED: Tue Jan 10 18:00:45 2023
    NAMESPACE: monitor
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    ```

检查监控告警组件是否运行正常:

```shell
kubectl get pods -n monitor
```

期望输出:

```text
NAME                          READY   STATUS    RESTARTS   AGE
grafana-5548d85c77-v9x69      1/1     Running   0          77s
node-exporter-67ggw           1/1     Running   0          77s
node-exporter-6gf2c           1/1     Running   0          77s
node-exporter-qz4jk           1/1     Running   0          77s
prometheus-645fcdf654-q4q59   2/2     Running   0          77s
```

当所有pod处于Running状态时，继续下一步。

## 第5步: 创建集群

默认会创建一主一从两个节点，如果需要多个节点，可通过Helm设置replicaCount参数实现，最高可支持7个副本。

```shell
helm install mycluster helm/mogdb-cluster --set enableHa=true --namespace mogdb-operator-system
```

期望输出:

```text
NAME: mycluster
LAST DEPLOYED: Wed Jan 11 11:17:53 2023
NAMESPACE: mogdb-operator-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying a MogDB Cluster!
```

检查pod是否运行正常

```shell
kubectl get pods -n mogdb-operator-system
```

期望输出:

```text
NAME                                       READY   STATUS    RESTARTS   AGE
cluster1-g3umz                             2/2     Running   0          3m48s
cluster1-s8sti                             2/2     Running   0          2m28s
mogdb-apiserver-699c855d9b-878qj           1/1     Running   0          17h
mogdb-operator-myproject-5cd5bb9d9-7xztz   1/1     Running   0          17h
```

当所有pod处于Running状态时，代表集群创建成功。

# Helm使用方法

## 添加仓库

```shell
helm repo add mogdb-chart https://enmotech.github.io/mogdb-stack-helm-charts
```

## 更新仓库

```shell
helm repo update mogdb-chart
```

## 查询目标仓库最新chart版本

```shell
helm search repo mogdb-chart
```

## 查询目标仓库所有的chart版本

```shell
helm search repo mogdb-chart -l
```

## 第一次安装（连同创建命名空间）

```shell
helm install mogdb mogdb-chart/mogdb-operator --namespace mogdb-operator-system --create-namespace
```

## 安装

```shell
helm install mogdb mogdb-chart/mogdb-operator --namespace mogdb-operator-system
```

## 列举发布版本

```shell
helm list
```

## 升级到最新版本

```shell
helm upgrade mogdb mogdb-chart/mogdb-operator
```

## 升级到指定版本

```shell
helm upgrade mogdb mogdb-chart/mogdb-operator --version=*****
```

## 回滚到某个chart版本

```shell
helm rollback mogdb [RELEASE REVISION]
```

## 添加chart版本

- 修改 mogdb-operator/values.yaml 文件中的 apiTag 和 managerTag 值为 mogdb-apiserver 和 mogdb-operator 对应镜像版本
- 修改 mogdb-operator/Chart.yaml 文件中的 version 值为一个新的 chart 版本 tag
- 检查需要新打包tag语法
    ```shell
    helm lint --strict mogdb-operator
    ```
- 打包
    ```shell
    helm package mogdb-operator
    ```
- 将新打的包添加到索引文件
    ```shell
    helm repo index --url https://enmotech.github.io/mogdb-stack-helm-charts/ .
    ```