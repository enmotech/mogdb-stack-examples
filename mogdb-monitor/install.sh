#!/bin/sh

kubectl get deploy og-operator-controller-manager -o name -n og-operator-system >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "Error:please deploy og-operator-controller-manager first"
  exit 1
fi

#创建namespace
kubectl get ns monitoring -o name >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "create namespace monitoring"
  kubectl create namespace monitoring
fi

#部署kube—state-metrics
kubectl get deploy kube-state-metrics -o name -n kube-system >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "deploy kube-state-metrics"
  kubectl apply -f kube-state-metrics/

  if [ $? -ne 0 ]
  then
    echo "Error:deploy kube-state-metrics failed"
    kubectl delete -f kube-state-metrics/ >/dev/null 2>&1
    exit 1
  fi

fi

#部署node-exporter
kubectl get daemonSet node-exporter -n monitoring -o name >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "deploy node-exporter"
  kubectl apply -f kubernetes-node-exporter/

  if [ $? -ne 0 ]; then
    echo "Error:deploy node-exporter failed"
    kubectl delete -f kubernetes-node-exporter/ >/dev/null 2>&1
    exit 1
  fi
fi

#部署prometheus
kubectl get deploy prometheus -o name -n monitoring >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "deploy prometheus"
  kubectl apply -f prometheus/

  if [ $? -ne 0 ]; then
    echo "Error:deploy prometheus failed"
    kubectl delete -f prometheus/ >/dev/null 2>&1
    exit 1
  fi
fi

#部署grafana
kubectl get deploy grafana -o name -n monitoring >/dev/null 2>&1

if [ $? -ne 0  ]; then
  echo "deploy grafana"
  kubectl apply -f grafana/

  if [ $? -ne 0 ]; then
    echo "deploy grafana failed"
    kubectl delete -f grafana/ >/dev/null 2>&1
    exit 1
  fi
fi

echo "success!"

exit 0