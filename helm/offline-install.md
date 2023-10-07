# MogDB stack 3.0 helm安装部署文档

## 环境说明

本文档旨在指导您在没有外部网络连接的环境中安装 MogDB Stack 3.0。这个过程需要在已经安装了 Kubernetes 版本 v1.21 以上的系统上进行，并需要您拥有一个私有的 Docker 镜像仓库来存储容器镜像。在开始之前，请确保满足以下环境要求：

- **Kubernetes 版本**: 您的系统必须已经安装并运行 Kubernetes 版本 >=v1.21。

- **私有 Docker 镜像仓库**: 您需要拥有一个私有的 Docker 镜像仓库，用于存储应用所需的容器镜像。这是因为在没有外部网络连接的环境中，无法从公共 Docker Hub 下载镜像。

- **Helm 安装**: 请确保已经安装了 Helm，这是 Kubernetes 的包管理工具，将用于安装 "MogDB Stack" 应用。

- **S3 存储**: MogDB Stack 依赖 S3 存储进行备份存储。需要提前提供 s3 存储，或使用 docker 安装minio提供存储功能

## 准备工作

当您准备部署  MogDB Stack 3.0 到您的 Kubernetes 环境之前，需要进行一些准备工作。以下是准备工作的详细内容：

**1. 准备 Docker 镜像**：
在部署 MogDB Stack 3.0 之前，我们提供了stack 3.0所有需要使用的镜像源。您可以使用 `docke load -i stack_3.0_images.tar`获取这些镜像。并且通过以下镜像源信息验证镜像的正确性。

准备的镜像源：

- **mutli-operator** : swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/multi-operator:3.0.0(Id: sha256:2466df680d728306368fdac50e29c2dec431068585a4207394808435914b2edb)

- **mogdb-operator** : swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/mogdb-operator:3.0.0(Id: sha256:b64d772b04aa328bcd4d9457b0b9cbd579a117f37c0c49f3c0ce01a1e37d8aca)

- **mogdb-ha** : swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/mogdb-ha:3.0.0(Id: sha256:14e7698572a9226428f049a7edb6637dab1241a0b63e580c1ebccc7c1d2c13f1)

- **mogdb** : swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/mogdb:3.0.4(Id: sha256:cbf8579e049741dcaf0f7a578a875da78b44b1228ed83741c1d7b65b09bbdd92)

- **mogdb-exporter** : swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/mogdb-exporter:3.0.3(Id: sha256:0bf8267f1af170c0abee8aca05b7eb0ed67f562808f046b1152a60b93fec4afa)

- **etcd** : registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.5.0-0(Id: sha256:2252d5eb703b0519569abad386ce39bcccc05b24a6b1619c3a646fe0746f9258)

- **remote-client** : swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/remote-client:3.0.0(Id: sha256:09640ed4bd7cc3841be20aba76d462b63a9f24b49962d93b98c1b91e547f9593)

- **minio** : quay.io/minio/minio:latest(Id: sha256:9701b708d3cb06a9c83b1cecde64e681d4cb5ef50dae7604b50f71edd5a6f572)

**2. 上传 Docker 镜像**：

获取到所有镜像并验证镜像的正确性之后，您可以执行 `docker tag` 以及 `docker push` 命令将这些镜像上传至您的镜像仓库中，方便后续helm安装使用。

例如：

```shell
docker tag swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/multi-operator:3.0.0 localhost:5000/multi-operator:3.0.0

docker push localhost:5000/multi-operator:3.0.0

docker tag swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/mogdb-operator:3.0.0 localhost:5000/mogdb-operator:3.0.0

docker push localhost:5000/mogdb-operator:3.0.0

docker tag swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/mogdb-ha:3.0.0 localhost:5000/mogdb-ha:3.0.0

docker push localhost:5000/mogdb-ha:3.0.0

docker tag swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/mogdb:3.0.4 localhost:5000/mogdb:3.0.4

docker push localhost:5000/mogdb:3.0.4

docker tag swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/mogdb-exporter:3.0.3 localhost:5000/mogdb-exporter:3.0.3

docker push localhost:5000/mogdb-exporter:3.0.3

docker tag swr.cn-north-4.myhuaweicloud.com/mogdb-cloud/remote-client:3.0.0 localhost:5000/remote-client:3.0.0

docker push localhost:5000/remote-client:3.0.0

docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.5.0-0 localhost:5000/etcd:3.5.0-0

docker push localhost:5000/etcd:3.5.0-0

docker tag quay.io/minio/minio:latest localhost:5000/minio:latest

docker push localhost:5000/minio:latest
```

**3. 上传 MogDB Stack 3.0 helm 源码**：

在GitHub上fork [MogDB Stack examples](https://github.com/enmotech/mogdb-stack-examples)仓库:

<https://github.com/enmotech/mogdb-stack-examples/fork>

fork仓库之后，您可以通过类似如下的命令下载至本地:

```shell
YOUR_GITHUB_UN="<your GitHub username>"
git clone --depth 1 "git@github.com:${YOUR_GITHUB_UN}/mogdb-stack-examples.git"
cd mogdb-stack-examples
```

将 `mogdb-stack-examples` 目录上传至您的环境中。

**4. 使用 docker 运行 minio**：

执行命令：

```shell
docker run -p 9000:9000 -p 9001:9001 --name minio -d --restart=always -e "MINIO_ACCESS_KEY=minioadmin" -e "MINIO_SECRET_KEY=minioadmin" -v ~/minio/data:/data -v ~/minio/config:/root/.minio localhost:5000/minio:latest server /data --console-address ":9001"
```

其中 `9000:9000` 表示将容器内的 MinIO 服务端口映射到本地的 9000 端口；`-e` 参数指定 MinIO 登录凭证（ACCESS\_KEY 和 SECRET\_KEY）

在浏览器中输入 `http://localhost:9000`，并使用之前设置的 ACCESS\_KEY 和 SECRET\_KEY 进行登录。如果能够正常登录，并且在 Web 界面上看到 MinIO 的管理页面，则表明 MinIO 已经成功安装，并且运行正常。

</br>

完成上述准备工作后，就可以使用 helm 安装部署 MogDB Stack 3.0了。

## 安装部署

MogDB Stack提供了两种模式，分别是单机群模式和多集群模式。单机群模式适用于单一的Kubernetes集群，在整个Kubernetes内实现MogDB集群的生命周期管理，多集群模式提供了一种跨Kubernetes/机房的方案，满足用户对于跨机房的容灾要求。您可以根据自己的需求选择哪种模式安装部署

</br>

### 单集群的安装部署

</br>

#### 1.安装 mogdb-ha

mogdb-ha是 MogDB Stack 体系中的高可用组件，以哨兵模式运行，并实时监测 MogDB 集群的运行状态，当监测到集群出现故障时，触发修复逻辑。

创建 namespace：

```shell
kubectl create namespace <ns>
```

期望输出：

```shell
$ kubectl create namespace mogdb-ha
namespace/mogdb-ha created
```

安装 mogdb-ha 组件，有关设置的详细配置在 `mogdb-stack-examples/helm/mogdb-ha/values.yaml` 文件查看。

执行命令：

```shell
cd mogdb-stack-examples
```

后续命令默认在 `mogdb-stack-examples` 下执行

`mogdb-ha` 安装命令如下：

```shell
helm install <name> helm/mogdb-ha -n <ns> [--set <config>=<balue>...]
```

​期望输出（在本例中，关闭了 debug 日志，使用简化版 etcd，并设置 ha 容器的内存大小为 1Gi，并使用私有仓库 mogdb-ha 和 etcd 镜像）：

```shell
$ helm install mogdb-ha helm/mogdb-ha -n mogdb-ha \
    --set debug=false \
    --set withEtcd=true \
    --set ha.resources.limits.memory=1Gi \
    --set ha.resources.requests.memory=1Gi \
    --set ha.image=localhost:5000/mogdb-ha:3.0.0 \
    --set etcd.image=localhost:5000/etcd:3.5.0-0 
NAME: mogdb-ha
LAST DEPLOYED: Wed Sep  6 17:06:10 2023
NAMESPACE: mogdb-ha
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Ha!
```

获取 mogdb-ha pod，并且查看 mogdb-ha 日志验证是否安装成功：

```shell
$ kubectl get pods -n mogdb-ha
NAME                        READY   STATUS    RESTARTS   AGE
mogdb-ha-6484bb799d-zcn7d   2/2     Running   0          19s

$ kubectl logs mogdb-ha-6484bb799d-zcn7d -n mogdb-ha
Defaulted container "mogha" out of: mogha, etcd
2023-09-06T09:06:11.959Z        INFO    mogha   ha server starting
{"level":"warn","ts":"2023-09-06T09:06:14.837Z","caller":"clientv3/retry_interceptor.go:62","msg":"retrying of unary invoker failed","target":"endpoint://client-7dc3eacd-2c57-43d2-8745-b8a552fcee8f/127.0.0.1:2379","attempt":0,"error":"rpc error: code = FailedPrecondition desc = etcdserver: authentication is not enabled"}
[GIN] 2023/09/06 - 09:06:21 | 200 |       82.04μs |      10.244.1.1 | GET      "/"
[GIN] 2023/09/06 - 09:06:31 | 200 |      67.801μs |      10.244.1.1 | GET      "/"
[GIN] 2023/09/06 - 09:06:41 | 200 |       53.33μs |      10.244.1.1 | GET      "/"
```

</br>

2.安装 mogdb-operator

创建 namespace：

```shell
kubectl create namespace <ns>
```

期望输出：

```shell
$ kubectl create namespace mogdb-operator-system
namespace/mogdb-operator-system created
```

</br>

安装 mogdb-operator，有关设置的详细配置在 `mogdb-stack-examples/helm/mogdb-operator/values.yaml` 文件查看。

`mogdb-operator` 安装命令如下：

```shell
helm install <name> helm/mogdb-operator -n <ns> [--set <config>=<balue>...]
```

​期望输出（在本例中，同时安装crd，使用私有仓库 mogdb-operator 镜像，并且使用 docker 安装 minio 的配置）：

```shell
$ helm install mogdb-operator helm/mogdb-operator -n mogdb-operator-system \
    --set withCRD=true \
    --set operator.image=localhost:5000/mogdb-operator:3.0.0 \
    --set rclone.s3.endpoint=http://localhost:9000 \
    --set rclone.s3.access_key=minioadmin \
    --set rclone.s3.secret_key=minioadmin 
NAME: mogdb-operator
LAST DEPLOYED: Thu Sep  7 15:17:55 2023
NAMESPACE: mogdb-operator-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Operator!
```

查看 crd ，验证有以下自定义资源安装成功：

```shell
$ kubectl get crd
NAME                                      CREATED AT
mogdbclusters.mogdb.enmotech.io           2023-09-07T07:17:56Z
mogdbclustertemplates.mogdb.enmotech.io   2023-09-07T07:17:56Z
mogdbpodtemplates.mogdb.enmotech.io       2023-09-07T07:17:56Z
```

获取 mogdb-operator pod，并且查看 mogdb-operator 日志验证是否安装成功：

```shell
$ kubectl get pods -n mogdb-operator-system
NAME                                            READY   STATUS    RESTARTS   AGE
mogdb-operator-mogdb-operator-bbd96cdd8-xhcf8   1/1     Running   0          3m33s

$ kubectl logs mogdb-operator-mogdb-operator-bbd96cdd8-xhcf8 -n mogdb-operator-system
time="2023-09-07T07:17:57Z" level=info msg="global config refreshed"
{"level":"info","ts":"2023-09-07T07:17:58.123Z","logger":"controller-runtime.metrics","msg":"Metrics server is starting to listen","addr":"127.0.0.1:8080"}
{"level":"info","ts":"2023-09-07T07:17:58.124Z","logger":"setup","msg":"starting manager"}
{"level":"info","ts":"2023-09-07T07:17:58.124Z","msg":"Starting server","path":"/metrics","kind":"metrics","addr":"127.0.0.1:8080"}
I0907 07:17:58.124690       1 leaderelection.go:248] attempting to acquire leader lease mogdb-operator-system/029c71aa.enmotech.io...
{"level":"info","ts":"2023-09-07T07:17:58.124Z","msg":"Starting server","kind":"health probe","addr":"[::]:8081"}
I0907 07:17:58.134759       1 leaderelection.go:258] successfully acquired lease mogdb-operator-system/029c71aa.enmotech.io
...
```

</br>

3.部署 mogdb-cluster 集群

部署 mogdb-cluster集群，有关设置的详细配置在 `mogdb-stack-examples/helm/mogdb-cluster/values.yaml` 文件查看。

`mogdb-operator` 安装命令如下：

```shell
helm install <name> helm/mogdb-cluster -n <ns> [--set <config>=<balue>...]
```

​期望输出（在本例中，设置 MogDB 容器 cpu 为 2 核，内存为16 g。并且存储盘大小为 100g，并且使用本地 mogdb、exporter镜像）：

```shell
$ helm install cluster helm/mogdb-cluster -n mogdb-operator-system \
    --set mogdb.resources.limits.cpu:2000m \
    --set mogdb.resources.limits.memory:16Gi \
    --set mogdb.resources.requests.cpu:2000m \
    --set mogdb.resources.requests.memory:16Gi \
    --set mogdb.volume.dataVolumeSize:100Gi \
    --set images.initImage=localhost:5000/mogdb:3.0.4 \
    --set images.mogdbImage=localhost:5000/mogdb:3.0.4 \
    --set images.exporterImage=localhost:5000/mogdb-exporter:3.0.3
NAME: cluster
LAST DEPLOYED: Thu Sep  7 17:17:04 2023
NAMESPACE: mogdb-operator-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Cluster!
```

查看 MogDB 节点以及service

```shell
$ kubectl get pods,svc -n mogdb-operator-system
NAME                                                READY   STATUS    RESTARTS   AGE
pod/cluster-sts-h78nm-0                             2/2     Running   0          7m31s
pod/cluster-sts-sm9bw-0                             2/2     Running   0          6m53s
pod/mogdb-operator-mogdb-operator-bbd96cdd8-xhcf8   1/1     Running   0          126m

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
service/cluster-svc-headless   ClusterIP   None            <none>        26000/TCP,9187/TCP   7m32s
service/cluster-svc-master     NodePort    10.96.216.131   <none>        26000:30013/TCP      7m32s
service/cluster-svc-replicas   NodePort    10.96.126.138   <none>        26000:30012/TCP      7m32s
```

这个时候就可以使用 gsql 等工具连接主机 30013（读写端口）30012（只读端口）来联通数据库了。

</br>

4.创建一次性备份

编辑备份参数文件 backup.yaml 如下:

```yaml
backup:
  image: localhost:5000/remote-client:3.0.0
  manual:
    id: "001"
    backupType: dumpall
    storageProvider:
      rcloneStorage:
        name: s3-remote
        directory: backup
```

字段详细相关内容查看 `mogdb-stack-examples/helm/mogdb-cluster/values.yaml` 文件。

执行以下命令更新 mogdb-cluster 创建一次性备份：

```shell
$ helm upgrade -f backup.yaml cluster helm/mogdb-cluster -n mogdb-operator-system 
Release "cluster" has been upgraded. Happy Helming!
NAME: cluster
LAST DEPLOYED: Thu Sep  7 17:54:17 2023
NAMESPACE: mogdb-operator-system
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Cluster!
```

查看备份任务：

```shell
$ kubectl get job,pods -n mogdb-operator-system
NAME                             COMPLETIONS   DURATION   AGE
job.batch/cluster-backup-sr9wq   1/1           11s        32m

NAME                                                READY   STATUS      RESTARTS   AGE
pod/cluster-backup-sr9wq-g98dx                      0/1     Completed   0          32m
pod/cluster-sts-h78nm-0                             2/2     Running     0          70m
pod/cluster-sts-sm9bw-0                             2/2     Running     0          69m
pod/mogdb-operator-mogdb-operator-bbd96cdd8-xhcf8   1/1     Running     0          3h9m
```

这个时候备份已经成功创建，在浏览器中输入 `http://localhost:9000` 登录minio查看备份文件是否成功创建。

</br>

5.对象恢复

编辑对象恢复参数文件 obj-restore.yaml 如下:

```yaml
restore:
  restoreId: "001"
  dataSource:
    type: "object"
    backupType: dumpall
    clusterName: cluster
    storageProvider:
      rcloneStorage:
        name: s3-remote
        directory: backup
    target: dumpall-2023-09-07-09-54-18.tar.gz
  image: localhost:5000/remote-client:3.0.0
```

字段详细相关内容查看 `mogdb-stack-examples/helm/mogdb-cluster/values.yaml` 文件。

执行以下命令更新 mogdb-cluster 创建对象恢复：

```shell
$ helm upgrade -f obj-restore.yaml cluster helm/mogdb-cluster -n mogdb-operator-system 
Release "cluster" has been upgraded. Happy Helming!
NAME: cluster
LAST DEPLOYED: Thu Sep  7 18:51:35 2023
NAMESPACE: mogdb-operator-system
STATUS: deployed
REVISION: 3
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Cluster!
```

查看对象恢复任务：

```shell
$ kubectl get job,pods -n mogdb-operator-system -l mogdb.enmotech.io/cluster=cluster,mogdb.enmotech.io/restore=object
NAME                              COMPLETIONS   DURATION   AGE
job.batch/cluster-restore-fngbr   1/1           1s         59s

NAME                                                READY   STATUS      RESTARTS   AGE
pod/cluster-restore-fngbr-xpzk5                     0/1     Completed   0          59s
```

对象恢复已经成功完成

</br>

6.管理备份计划

编辑定时备份参数文件 auto-backup.yaml 如下:

```yaml
backup:
  auto:
    name: "auto"
    backupSchedules:
      full: "*/1 * * * *"
    storageProvider:
      rcloneStorage:
        name: s3-remote
        directory: backup
    backupType: basebackup
    backupFileHistoryLimit: 7
    failedJobsHistoryLimit: 7
    successfulJobsHistoryLimit: 7
  image: localhost:5000/remote-client:3.0.0
```

执行以下命令更新 mogdb-cluster 创建定时备份：

```shell
$ helm upgrade -f auto-backup.yaml cluster helm/mogdb-cluster -n mogdb-operator-system 
Release "cluster" has been upgraded. Happy Helming!
NAME: cluster
LAST DEPLOYED: Fri Sep  8 09:44:08 2023
NAMESPACE: mogdb-operator-system
STATUS: deployed
REVISION: 4
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Cluster!
```

查看自动备份任务：

```shell
$ kubectl get cronjob,job,pods -n mogdb-operator-system
NAME                              SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/cluster-auto-full   */1 * * * *   False     0        41s             2m33s

NAME                                   COMPLETIONS   DURATION   AGE
job.batch/cluster-auto-full-28235625   1/1           14s        101s
job.batch/cluster-auto-full-28235626   1/1           14s        41s
job.batch/cluster-backup-sr9wq         1/1           11s        15h
job.batch/cluster-restore-fngbr        1/1           1s         14h

NAME                                                READY   STATUS      RESTARTS   AGE
pod/cluster-auto-full-28235625-gtp6m                0/1     Completed   0          101s
pod/cluster-auto-full-28235626-m9z7s                0/1     Completed   0          41s
pod/cluster-backup-sr9wq-g98dx                      0/1     Completed   0          15h
pod/cluster-restore-fngbr-xpzk5                     0/1     Completed   0          14h
pod/cluster-sts-h78nm-0                             2/2     Running     0          16h
pod/cluster-sts-sm9bw-0                             2/2     Running     0          16h
pod/mogdb-operator-mogdb-operator-bbd96cdd8-xhcf8   1/1     Running     0          18h
```

浏览器中输入 `http://localhost:9000` 登录minio查看对应备份文件是否生成。

</br>

7.时间恢复

**注意：进行时间恢复前请确保 S3 存储中在恢复时间点之前有当日备份文件。**

编辑时间恢复参数文件 time-restore.yaml 如下:

```yaml
restore:
  restoreId: "002"
  dataSource:
    type: "time"
    backupType: basebackup
    clusterName: cluster
    storageProvider:
      rcloneStorage:
        name: s3-remote
        directory: backup
    target: "2023-09-08T09:32:15.17"
  image: localhost:5000/remote-client:3.0.0
```

执行以下命令更新 mogdb-cluster 创建对象恢复：

```shell
$ helm upgrade -f time-restore.yaml cluster helm/mogdb-cluster -n mogdb-operator-system 
Release "cluster" has been upgraded. Happy Helming!
NAME: cluster
LAST DEPLOYED: Fri Sep  8 16:47:11 2023
NAMESPACE: mogdb-operator-system
STATUS: deployed
REVISION: 5
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Cluster!
```

查看时间恢复任务：

```shell
$ kubectl get job,pods -n mogdb-operator-system -l mogdb.enmotech.io/cluster=cluster,mogdb.enmotech.io/restore=time
NAME                                   COMPLETIONS   DURATION   AGE
job.batch/cluster-restore-9rm8h        1/1           42s        3m42s

NAME                                                READY   STATUS      RESTARTS   AGE
pod/cluster-restore-9rm8h-m5khj                     0/1     Completed   0          3m47s
```

时间恢复已经成功完成

</br>

8.删除 mogdb-cluster 集群

执行命令：

```shell
$ helm delete cluster -n mogdb-operator-system
release "cluster" uninstalled
```

查看 mogdb-operator-system 命名空间下的内容，发现所有 mogdb-cluster 相关内容已经全部删除

```shell
kubectl get all -n mogdb-operator-system
NAME                                                READY   STATUS    RESTARTS   AGE
pod/mogdb-operator-mogdb-operator-bbd96cdd8-xhcf8   1/1     Running   4          25h

NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mogdb-operator-mogdb-operator   1/1     1            1           25h

NAME                                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/mogdb-operator-mogdb-operator-bbd96cdd8   1         1         1       25h
```

</br>

### 多集群的安装部署

提前了解以下术语将有助于您阅读本文档。

- 数据平面：数据层，mogdb 真实存在的位置；
- 数据中心：每个数据平面被称为一个数据中心；
- 控制平面：控制层，用于控制 mogdb 在多个数据中心上的分配逻辑；

注意：控制平面、数据平面、数据中心均为逻辑概念。实际上，控制平面和数据平面出现在同一 kubernetes 集群中是被允许的，多个数据平面也可以同时出现在一个 kubernetes 集群中。**在生产环境中我们推荐将控制平面、数据平面分开部署。**

在本例中选用两个k8s集群 A、B 安装部署 Mogdb Stack 多中心集群应用，其中控制平面和数据平面2安装在 A 集群，数据平面1安装在 B 集群。并且需要创建 A、B 两个集群的共用的 IP 池。

</br>

1.安装 mogdb-ha

我们已经了解mogdb-ha是 MogDB Stack 体系中的高可用组件。在Mogdb Stack 多中心集群中，mogdb-ha需要和所有 mogdb 在同一个网络段下。

创建命名空间：

```shell
$ kubectl create namespace mogdb
namespace/mogdb created
```

安装 mogdb-ha(在本例中，关闭了 debug 日志，使用简化版 etcd，并设置 ha 容器的内存大小为 1Gi，并使用私有仓库 mogdb-ha 和 etcd 镜像，规定 mogdb-ha 的 pod 的 ip 在 `vlan424-mogdb` ip池中)

```shell
$ helm install multi-mogdb-ha helm/mogdb-ha -n mogdb \
    --set debug=false \
    --set withEtcd=true \
    --set ha.resources.limits.memory=1Gi \
    --set ha.resources.requests.memory=1Gi \
    --set ha.image=localhost:5000/mogdb-ha:3.0.0 \
    --set etcd.image=localhost:5000/etcd:3.5.0-0 \
    --set annotations."dce\.daocloud\.io\/parcel\.net\.type"=ovs \
    --set annotations."dce\.daocloud\.io\/parcel\.net\.value"="pool\:vlan424-mogdb"
NAME: multi-mogdb-ha
LAST DEPLOYED: Fri Sep  8 14:44:39 2023
NAMESPACE: mogdb
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Ha!
```

获取 mogdb-ha pod，并且查看 mogdb-ha 日志验证是否安装成功：

```shell
$ kubectl get pods -n mogdb
NAME                              READY   STATUS    RESTARTS   AGE
multi-mogdb-ha-5f9d76f6db-vgg5h   2/2     Running   0          58s

$ kubectl logs multi-mogdb-ha-5f9d76f6db-vgg5h -n mogdb
Defaulted container "mogha" out of: mogha, etcd
2023-09-08T06:44:40.104Z        INFO    mogha   ha server starting
{"level":"warn","ts":"2023-09-08T06:44:41.108Z","caller":"clientv3/retry_interceptor.go:62","msg":"retrying of unary invoker failed","target":"endpoint://client-f01d32ff-7016-4a07-9f68-770a61a78e18/127.0.0.1:2379","attempt":0,"error":"rpc error: code = FailedPrecondition desc = etcdserver: authentication is not enabled"}
[GIN] 2023/09/08 - 06:44:59 | 200 |      89.351μs |      10.244.1.1 | GET      "/"
[GIN] 2023/09/08 - 06:45:09 | 200 |      90.831μs |      10.244.1.1 | GET      "/"
[GIN] 2023/09/08 - 06:45:19 | 200 |      98.361μs |      10.244.1.1 | GET      "/"
```

</br>

2.安装控制平面

**注意：只能同时存在一个控制平面。**

在开始之前，确保您已创建控制平面上下文，并且将 kubectl 的切换到控制平面：

```shell
kubectl config set-context <control-plane-context> --namespace=<control-plane-namespace> --cluster=<k8s-cluster> --user=<k8s-user>

kubectl config use-context <control-plane-context>
```

期望输出：

```shell
$ kubectl config set-context control-plane --namespace=control-plane --cluster=local --user=admin
Context "control-plane" created.

$ kubectl config use-context control-plane
Switched to context "control-plane".
```

创建命名空间：

```shell
$ kubectl create namespace control-plane
namespace/control-plane created
```

安装 multi-operator，有关设置的详细配置在 `mogdb-stack-examples/helm/multi-operator/values.yaml` 文件查看。

`multi-operator` 安装命令如下：

```shell
helm install <name> helm/multi-operator -n <ns> [--set <config>=<balue>...]
```

​期望输出（在本例中，同时安装crd，使用私有仓库 multi-operator 镜像）：

```shell
$ helm install multi-operator helm/multi-operator -n control-plane \
    --set withCRD=true \
    --set operator.image=localhost:5000/multi-operator:3.0.0
NAME: multi-operator
LAST DEPLOYED: Fri Sep  8 14:58:06 2023
NAMESPACE: control-plane
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Multi Operator!
```

查看 crd ，验证有以下自定义资源安装成功：

```shell
$ kubectl get crd
NAME                                      CREATED AT
kubeclientconfigs.mogdb.enmotech.io       2023-09-08T06:58:07Z
multiclusters.mogdb.enmotech.io           2023-09-08T06:58:07Z
```

获取 multi-operator pod，并且查看 multi-operator 日志验证是否安装成功：

```shell
$ kubectl get pods -n control-plane
NAME                                            READY   STATUS    RESTARTS   AGE
multi-operator-multi-operator-9d46b4554-bdhbw   1/1     Running   0          119s

$ kubectl logs mogdb-operator-mogdb-operator-bbd96cdd8-xhcf8 -n mogdb-operator-system
2023-09-08T06:58:09.309Z        INFO    controller-runtime.metrics      Metrics server is starting to listen    {"addr": "127.0.0.1:8080"}
2023-09-08T06:58:09.310Z        INFO    setup   starting manager
2023-09-08T06:58:09.310Z        INFO    Starting server {"path": "/metrics", "kind": "metrics", "addr": "127.0.0.1:8080"}
I0908 06:58:09.310471       1 leaderelection.go:248] attempting to acquire leader lease control-plane/029c71aa.enmotech.io...
2023-09-08T06:58:09.310Z        INFO    Starting server {"kind": "health probe", "addr": "[::]:8081"}
I0908 06:58:09.318982       1 leaderelection.go:258] successfully acquired lease control-plane/029c71aa.enmotech.io
...
```

</br>

3.安装部署数据平面

在 A 集群中完成了对 mogdb-ha 和 控制平面控制 multi-operator 的安装，接下来我们将数据平面1 安装在 B 集群。

创建控制平面1 上下文，并且将 kubectl 的切换到其中：

```shell
kubectl config set-context <data-plane-context> --namespace=<data-plane-namespace> --cluster=<k8s-cluster> --user=<k8s-user>

kubectl config use-context <data-plane-context>
```

期望输出：

```shell
$ kubectl config set-context data-plane1 --namespace=data-plane1 --cluster=local --user=admin
Context "data-plane1" created.

$ kubectl config use-context data-plane1
Switched to context "data-plane1".
```

创建命名空间：

```shell
$ kubectl create namespace data-plane1
namespace/data-plane1 created
```

安装 mogdb-operator（在本例中，同时安装crd，使用私有仓库 mogdb-operator 镜像）：

```shell
$ helm install mogdb-operator-1 helm/mogdb-operator -n data-plane1 \
    --set withCRD=true \
    --set operator.image=localhost:5000/mogdb-operator:3.0.0 
NAME: mogdb-operator-1
LAST DEPLOYED: Fri Sep  8 15:22:58 2023
NAMESPACE: data-plane1
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Operator!
```

查看 crd ，验证有以下自定义资源安装成功：

```shell
$ kubectl get crd
NAME                                      CREATED AT
mogdbclusters.mogdb.enmotech.io           2023-09-08T07:11:23Z
mogdbclustertemplates.mogdb.enmotech.io   2023-09-08T07:11:23Z
mogdbpodtemplates.mogdb.enmotech.io       2023-09-08T07:11:23Z
```

获取 mogdb-operator pod，并且查看 mogdb-operator 日志验证是否安装成功：

```shell
$ kubectl get pods -n data-plane1
NAME                                               READY   STATUS    RESTARTS   AGE
mogdb-operator-mogdb-operator-1-7c7cff769d-qjkql   1/1     Running   0          96s

$ kubectl logs mogdb-operator-mogdb-operator-1-7c7cff769d-qjkql -n data-plane1
time="2023-09-08T07:22:59Z" level=info msg="global config refreshed"
{"level":"info","ts":"2023-09-08T07:23:00.556Z","logger":"controller-runtime.metrics","msg":"Metrics server is starting to listen","addr":"127.0.0.1:8080"}
{"level":"info","ts":"2023-09-08T07:23:00.557Z","logger":"setup","msg":"starting manager"}
{"level":"info","ts":"2023-09-08T07:23:00.557Z","msg":"Starting server","path":"/metrics","kind":"metrics","addr":"127.0.0.1:8080"}
I0908 07:23:00.557493       1 leaderelection.go:248] attempting to acquire leader lease data-plane1/029c71aa.enmotech.io...
{"level":"info","ts":"2023-09-08T07:23:00.557Z","msg":"Starting server","kind":"health probe","addr":"[::]:8081"}
I0908 07:23:00.563766       1 leaderelection.go:258] successfully acquired lease data-plane1/029c71aa.enmotech.io
...
```

此时，数据平面1 已经成功部署，回到 A 集群，同样的操作完成对数据平面2 的安装部署。

</br>

创建数据平面2 上下文，并且将 kubectl 切换其中：

```shell
$ kubectl config set-context data-plane2 --namespace=data-plane2 --cluster=local --user=admin
Context "data-plane2" created.

$ kubectl config use-context data-plane2
Switched to context "data-plane2".
```

创建命名空间：

```shell
$ kubectl create namespace data-plane2
namespace/data-plane2 created
```

安装 数据平面2 中的 mogdb-operator：

```shell
$ helm install mogdb-operator-2 helm/mogdb-operator -n data-plane2 \
    --set withCRD=true \
    --set operator.image=localhost:5000/mogdb-operator:3.0.0 
NAME: mogdb-operator-2
LAST DEPLOYED: Fri Sep  8 15:33:45 2023
NAMESPACE: data-plane2
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Operator!
```

</br>

4.注册数据平面到控制平面

将 B 集群的的 `~/.kube/config` 文件 复制到 A 集群路径下。并且修改 apiserver 地址为外部可访问 B 集群 apiserver地址，如下所示：

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: xxxxxxxx
    server: https://26.9.16.10:16443      #外部可访问 B 集群 apiserver地址
```

执行脚本将数据平面1 注册到控制平面：

```shell
$ ./join-to-control-plane.sh \
 --output-dir ./build \
 --src-kubeconfig ./data-plane1-config \
 --src-context data-plane1 \
 --src-namespace data-plane1 \
 --src-serviceaccount mogdb-operator-controller-manager \
 --dest-kubeconfig ~/.kube/config \
 --dest-context control-plane \
 --dest-namespace control-plane

Creating KubeConfig at ./build/kubeconfig
Creating secret data-plane1
Error from server (NotFound): secrets "data-plane1" not found
secret/data-plane1 created
Creating ClientConfig ./build/data-plane1.yaml
kubeclientconfig.mogdb.enmotech.io/data-plane1 created
```

执行脚本将数据平面2 注册到控制平面：

```shell
$ ./join-to-control-plane.sh \ 
--output-dir ./build \  
--src-kubeconfig ~/.kube/config \  
--src-context data-plane2 \  
--src-namespace data-plane2 \  
--src-serviceaccount mogdb-operator-controller-manager \ 
--dest-kubeconfig ~/.kube/config \
--dest-context control-plane \
--dest-namespace control-plane

Source cluster had localhost as the API server address; replacing with https://26.9.17.10:16443
Creating KubeConfig at ./build/kubeconfig
Creating secret data-plane2
Error from server (NotFound): secrets "data-plane2" not found
secret/data-plane2 created
Creating ClientConfig ./build/data-plane2.yaml
kubeclientconfig.mogdb.enmotech.io/data-plane2 created
```

查看 multi-operator 日志，出现以下内容验证数据平面1 数据平面2 成功注册到控制平面中：

```shell
$ kubectl get pods -n control-plane
NAME                                            READY   STATUS    RESTARTS   AGE
multi-operator-multi-operator-9d46b4554-bdhbw   1/1     Running   0          60m

$ kubectl logs multi-operator-multi-operator-9d46b4554-bdhbw -n control-plane
...
2023-09-08T07:53:57.293Z        INFO    clientconfig-controller reconcile kubeClientConfig end  {"controller": "kubeclientconfig", "controllerGroup": "mogdb.enmotech.io", "controllerKind": "KubeClientConfig", "KubeClientConfig": {"name":"data-plane1","namespace":"control-plane"}, "namespace": "control-plane", "name": "data-plane1", "reconcileID": "5ef343e1-6fde-4345-aefa-6b23d38ca3ce", "reconcile": "control-plane/data-plane1"}
2023-09-08T08:01:15.507Z        INFO    clientconfig-controller reconcile kubeClientConfig start        {"controller": "kubeclientconfig", "controllerGroup": "mogdb.enmotech.io", "controllerKind": "KubeClientConfig", "KubeClientConfig": {"name":"data-plane2","namespace":"control-plane"}, "namespace": "control-plane", "name": "data-plane2", "reconcileID": "b659135e-cb00-4373-9692-8af407093cb5", "reconcile": "control-plane/data-plane2"}
...
```

5.安装multi-cluster

在多机房 MogDB 集群中，我们已经将 mogdb-ha 加入 A、B 集群公用的ip池中，mulit-cluster 的部署需要指定 mogdb-ha 地址，并且所有mogdb 节点需要部署在 mogdb-ha 同一命名空间下。

在 B 集群中创建命名空间：

```shell
$ kubectl create namespace mogdb
namespace/mogdb created
```

查看 mogdb-ha ip 地址：

```shell
$ kubectl get pods -n mogdb -o wide
NAME                              READY   STATUS    RESTARTS   AGE    IP            NODE          NOMINATED NODE   READINESS GATES
multi-mogdb-ha-5f9d76f6db-vgg5h   2/2     Running   0          177m   10.244.1.61   master-node   <none>           <none>
```

> 由于多机房 mogdb 的 helm values 文件较为复杂。
>
> 我们建议您编辑 helm values 文件。而不是使用 --set 传递参数。

打开并编辑 `mogdb-stack-examples/helm/multi-cluser/values.yaml` 文件。本例编辑设置：

- 制定 mogdb 命名空间
- MogDB 容器 cpu 为 2 核，内存为16 g。存储盘大小为 100g。
- 使用私有仓库 mogdb、exporter 镜像。
- 使用 docker 安装 minio 的配置。
- 规定 mogdb 的 pod 的 ip  在 `vlan424-mogdb` ip池中。

```yaml
# Default values for mogdb.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

primaryDC:
  name: dc1
  namespace: mogdb    
  region: "dc1"
  kubeContextName: "data-plane1"
  spec:
    replica: 2
    readPort: 30012
    writePort: 30013
    mogdb:
      resources:
        limits:
          cpu: 2000m
          memory: 16Gi
        requests:
          cpu: 2000m
          memory: 16Gi
      volume:
        dataVolumeSize: 100Gi
        storageClass: default

standbyDCs:
  - name: dc2
    namespace: mogdb          
    region: "dc2"
    kubeContextName: "data-plane2"
    spec:
      replica: 2
      readPort: 30014
      writePort: 30015
      mogdb:
        resources:
          limits:
            cpu: 2000m
            memory: 16Gi
          requests:
            cpu: 2000m
            memory: 16Gi
        volume:
          dataVolumeSize: 100Gi
          storageClass: default


templates:
  replica: 2
  service:
    readPort: 30012
    writePort: 30013
  mogdb:
    resources:
      limits:
        cpu: 2000m
        memory: 16Gi
      requests:
        cpu: 2000m
        memory: 16Gi
    volume:
      dataVolumeSize: 100Gi
      storageClass: default
  ha:
    url: http://10.244.1.61:6544 
  images:
    imagePullPolicy: IfNotPresent
    mogdbImage: 26.9.17.10:5000/mogdb:3.0.4
    initImage: 26.9.17.10:5000/mogdb:3.0.4
    exporterImage: 26.9.17.10:5000/mogdb-exporter:3.0.3
  annotations:
    dce.daocloud.io/parcel.net.type: ovs 
    dce.daocloud.io/parcel.net.value: 'pool:vlan424-mogdb'

backup: {}

restore: {}

rclone:
  s3:
    provider: Minio
    endpoint: http://26.9.17.10:9000
    access_key: minioadmin
    secret_key: minioadmin
```

执行安装命令：

```shell
$ helm install multi-cluster1 helm/multi-cluster -n mogdb
NAME: multi-cluster1
LAST DEPLOYED: Fri Sep  8 18:05:27 2023
NAMESPACE: mogdb
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for deploying MogDB Multi Cluster!
```

执行以下命令查看自定义资源安装后的结果：
```shell
$ kubectl describe multiclusters -n mogdb
```

```yaml
Spec:
  Data Centers:
    Data Center Role:  primary
    Data Center Spec:
      Pod Spec:
        Backup Volume Spec:
          Persistent Volume Claim:
            Access Modes:
              ReadWriteOnce
            Resources:
              Requests:
                Storage:         2Gi
            Storage Class Name:  default
        Resources:
          Limits:
            Cpu:     500m
            Memory:  1Gi
          Requests:
            Cpu:     500m
            Memory:  1Gi
        Volume Spec:
          Persistent Volume Claim:
            Access Modes:
              ReadWriteOnce
            Resources:
              Requests:
                Storage:         2Gi
            Storage Class Name:  default
      Read Port:                 30012
      Replicas:                  2
      Write Port:                30013
    Kube Context Name:           data-plane1
    Name:                        dc1
    Namespace:                   mogdb
    Region:                      dc1


    Data Center Role:            standby
    Data Center Spec:
      Pod Spec:
        Backup Volume Spec:
          Persistent Volume Claim:
            Access Modes:
              ReadWriteOnce
            Resources:
              Requests:
                Storage:         1Gi
            Storage Class Name:  default
        Resources:
          Limits:
            Cpu:     500m
            Memory:  1Gi
          Requests:
            Cpu:     500m
            Memory:  1Gi
        Volume Spec:
          Persistent Volume Claim:
            Access Modes:
              ReadWriteOnce
            Resources:
              Requests:
                Storage:         1Gi
            Storage Class Name:  default
      Read Port:                 30014
      Replicas:                  2
      Write Port:                30015
    Kube Context Name:           data-plane2
    Name:                        dc2
    Namespace:                   mogdb
    Region:                      dc2
  Secrets Provider:              internal
  Template:
    Ha:
      Scope:  multi-cluster1
      URL:    http://mogdb-ha.mogdb.svc.cluster.local:6544
    Pod Spec:
      Backup Volume Spec:
        Persistent Volume Claim:
          Access Modes:
            ReadWriteOnce
          Resources:
            Requests:
              Storage:         1Gi
          Storage Class Name:  default
      Exporter Image:          localhost:5000/mogdb-exporter:3.0.3
      Image:                   localhost:5000/mogdb:3.0.4
      Image Pull Policy:       IfNotPresent
      Init Image:              localhost:5000/mogdb:3.0.4
      Resources:
        Limits:
          Cpu:     500m
          Memory:  1Gi
        Requests:
          Cpu:     500m
          Memory:  1Gi
      Volume Spec:
        Persistent Volume Claim:
          Access Modes:
            ReadWriteOnce
          Resources:
            Requests:
              Storage:         1Gi
          Storage Class Name:  default
    Read Port:                 30012
    Replicas:                  2
    Write Port:                30013

```
A 集群运行以下命令观察安装结果：

```shell
$ kubectl get all -n mogdb
NAME                                  READY   STATUS    RESTARTS   AGE
pod/dc2-sts-j4t74-0                   2/2     Running   0          2d12h
pod/dc2-sts-s7kpf-0                   2/2     Running   0          2d12h
pod/multi-mogdb-ha-5f9d76f6db-vgg5h   2/2     Running   0          2d19h

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
service/dc2-svc-headless   ClusterIP   None            <none>        26000/TCP,9187/TCP   2d12h
service/dc2-svc-master     NodePort    10.96.91.210    <none>        26000:30015/TCP      2d12h
service/dc2-svc-replicas   NodePort    10.96.78.144    <none>        26000:30014/TCP      2d12h
service/multi-mogdb-ha     ClusterIP   10.96.226.55    <none>        6544/TCP             2d19h

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/multi-mogdb-ha   1/1     1            1           2d19h

NAME                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/multi-mogdb-ha-5f9d76f6db   1         1         1       2d19h

NAME                             READY   AGE
statefulset.apps/dc2-sts-j4t74   1/1     2d12h
statefulset.apps/dc2-sts-s7kpf   1/1     2d12h
```

B 集群运行以下命令观察安装结果：

```shell
$ kubectl get all -n mogdb
NAME                                  READY   STATUS    RESTARTS   AGE
pod/dc1-sts-s5k2h-0                   2/2     Running   0          2d13h
pod/dc1-sts-t7qd9-0                   2/2     Running   0          2d13h

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
service/dc1-svc-headless   ClusterIP   None            <none>        26000/TCP,9187/TCP   2d13h
service/dc1-svc-master     NodePort    10.96.165.101   <none>        26000:30013/TCP      2d13h
service/dc1-svc-replicas   NodePort    10.96.180.237   <none>        26000:30012/TCP      2d13h

NAME                             READY   AGE
statefulset.apps/dc1-sts-s5k2h   1/1     2d13h
statefulset.apps/dc1-sts-t7qd9   1/1     2d13h
```

此时，multi-cluster 已经安装完成。因为主机房设定为 `data-plane1` 上下文所在集群。MogDB主节点部署在 B 集群，可通过 dc1-svc-master(读写)，dc1-svc-replicas(只读)，dc2-svc-replicas(只读)连接 MogDB 数据库。当主节点切换至 A 集群时，dc2-svc-master 将承担读写端口的责任。

</br>

6.备份与恢复

备份恢复方式同单机房 使用 helm 形式相同，不再赘述。
