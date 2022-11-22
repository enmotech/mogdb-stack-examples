# og operator单点prometheus部署

本文建立在已经构建好k8s集群环境，并且成功部署og-operator controller manager

##一、部署prometheus 和 各监控指标

###1、创建namespace

```bash
kubectl create namespace monitoring
```

###2、cAdvisor监控指标

在k8s中不需要单独安装，cAdvisor作为kubelet内置部分可以直接使用,他的数据通过kubelet暴露的api去访问，prometheus主要通过k8s服务发现的node模式采集各节点kubelet的基本运行状态相关监控指标，cAdvisor在prometheus中的相关配置：

```yaml
- job_name: 'kubernetes-cadvisor'
    kubernetes_sd_configs:
    - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - target_label: __address__
      replacement: kubernetes.default.svc:443
    - source_labels: [__meta_kubernetes_node_name]
      regex: (.+)
      target_label: __metrics_path__
      replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
```

###3、kube-state-metrics监控指标

####1.下载
```bash
$ cd ～
$ git clone https://github.com/kubernetes/kube-state-metrics.git
$ cd kube-state-metrics-master/examples/standard
$ ls
cluster-role-binding.yaml cluster-role.yaml deployment.yaml service-account.yaml service.yaml
```

####2.在service.yaml追加如下annotation
```yaml
annotations:
  prometheus.io/scraped: "true"
```
修改后的service.yaml文件：
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: kube-state-metrics
    app.kubernetes.io/version: v1.9.8
  name: kube-state-metrics
  namespace: kube-system
  annotations:
    prometheus.io/scrape: 'true'
spec:
  clusterIP: None
  ports:
  - name: http-metrics
    port: 8080
    targetPort: http-metrics
  - name: telemetry
    port: 8081
    targetPort: telemetry
  selector:
    app.kubernetes.io/name: kube-state-metrics
```

####3.启动服务
```bash
$ cd ～/kube-state-metrics-master/examples/standard
$ kubectl create -f .
```
prometheus以k8s服务发现抓取带有prometheus.io/scraped: "true" 注解的endpoint，kube-state-metrics在prometheus中的相关配置：
```yaml
- job_name: 'kube-state-metrics'
    kubernetes_sd_configs:
    - role: endpoints
    relabel_configs:
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scraped]
      action: keep
      regex: true
    - action: labelmap
      regex: __meta_kubernetes_service_label_(.+)
    - source_labels: [__meta_kubernetes_namespace]
      action: replace
      target_label: kubernetes_namespace
    - source_labels: [__meta_kubernetes_service_name]
      action: replace
      target_label: service_name
```

###4、node-exporter监控指标

####1.下载
```bash
$ cd ～
$ git clone https://github.com/bibinwilson/kubernetes-node-exporter.git
$ cd kubernetes-node-exporter
$ ls
README.md  daemonset.yaml  service.yaml
```

####2.启动服务
```bash
$ cd ～/kubernetes-node-exporter
$ kubectl create -f .
```

node-exporter在prometheus中的相关配置:
```yaml
- job_name: 'node-exporter'
    kubernetes_sd_configs:
    - role: endpoints
    relabel_configs:
    - source_labels: [__meta_kubernetes_endpoints_name]
      regex: 'node-exporter'
      action: keep
```

###5、部署operator集群，获取openguass-exporter监控指标

####1.部署集群
```bash
$ cd ～/prometheusPoint
$ kubectl create -f og_cluster.yaml
```
openguass-exporter在prometheus中的相关配置：
```yaml
- job_name: 'opengauss-exporter'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
    - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      action: replace
      regex: ([^:]+)(?::\d+)?;(\d+)
      replacement: $1:$2
      target_label: __address__
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)
    - source_labels: [__meta_kubernetes_namespace]
      action: replace
      target_label: kubernetes_namespace
    - source_labels: [__meta_kubernetes_pod_name]
      action: replace
      target_label: kubernetes_pod_name
```

###6、部署prometheus

```bash
$ cd ～/prometheusPoint/prometheus
$ kubectl create -f .
```

prometheus重要配置项字段解析：
```yaml
prometheus.rules: #报警规则

prometheus.yml: #配置信息
  global: #全局配置
    scrape_interval: #抓取周期，默认1分钟
    evaluation_interval: #估算规则的周期，默认1分钟
scrape_configs: #抓取配置列表
  - job_name: #任务名称，自动作为抓取到的指标的一个标签
    kubernetes_sd_configs: #K8S服务发现配置
    - role: # prometheus通过于k8s API集成5种服务发现模式，分别是Node、Service、Pod、Endpoints、Ingress
    relabel_configs: #目标重打标签配置
    - source_labels: #源标签
      regex: #正则表达式匹配源标签的值
      action: #基于正则表达式匹配执行的操作
      target_label: #重新标记的标签
      replacement: #替换正则表达式匹配的分组，分组引用 $1,$2,$3
    static_configs: #抓取目标的静态配置
    scheme: #抓去协议，默认值http
    tls_config: #TLS配置
    bearer_token_file: #读取Authorization请求头的文件
```

###7、部署grafana

```bash
$ cd ～/prometheusPoint/grafana
$ kubectl create -f .
```



##二、验证数据

###1、验证prometheus

* 打开<ip地址>:31000,验证prometheus是否拿到监控指标，如图所示：在status->targets 可观察到监控目标，状态为"up"说明拿到监控指标

![avatar](templates/img/prometheus_success.png)


* 或者在Graph中查询各监控指标数据

![avatar](templates/img/img.png)

![avatar](templates/img/img_1.png)

###2、验证grafana

* 打开<ip地址>:32000，显示prafana登陆界面，输入默认账号密码：admin/admin，添加数据源，选择prometheus，填写URL：<ip地址>:32000
* 在 https://grafana.com/grafana/dashboards/ 中可搜索各监控指标的dashboard,导入dashboard后可观察界面

![avatar](templates/img/img_2.png)