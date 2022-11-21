#!/bin/sh

kubectl delete -f kube-state-metrics/
kubectl delete -f kubernetes-node-exporter/
kubectl delete -f prometheus/
kubectl delete -f grafana/