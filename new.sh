#! /bin/bash
set -e
stack_examples_path=$(cd $(dirname $0); pwd)
# if do not use kind for k8s, comment next line
$stack_examples_path/setup-kind-multicluster.sh -o
wait

kubectl create ns mogdb-ha
kubectl apply --server-side -k $stack_examples_path/kustomize/mogdb-ha/install
kubectl apply --server-side -k $stack_examples_path/kustomize/mogdb-operator/bases/crd
kubectl create ns mogdb-operator-system
kubectl apply --server-side -k $stack_examples_path/kustomize/mogdb-operator/install/default
kubectl apply --server-side -k $stack_examples_path/kustomize/mogdb-cluster/install/default
kubectl get pods -A
