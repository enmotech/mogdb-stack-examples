# mogdb-stack-helm-charts
mogdb-stack-helm-charts

**Keep helm version >= 3.2**

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