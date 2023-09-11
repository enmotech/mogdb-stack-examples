#! /bin/bash
set -e
stack_examples_path=$(cd $(dirname $0); pwd)
# if do not use kind for k8s, comment next line
$stack_examples_path/setup-kind-multicluster.sh -o
wait

# set different contexts
kubectl config set-context control-plane --namespace=control-plane --cluster=kind-mogdb-stack-0 --user=kind-mogdb-stack-0
kubectl config set-context data-plane1 --namespace=data-plane1 --cluster=kind-mogdb-stack-0 --user=kind-mogdb-stack-0
kubectl config set-context data-plane2 --namespace=data-plane2 --cluster=kind-mogdb-stack-0 --user=kind-mogdb-stack-0

# install mogha
kubectl config use-context control-plane
kubectl create ns mogdb-ha
kubectl apply --server-side -k $stack_examples_path/kustomize/mogdb-ha/install

# install control-plane
kubectl apply --server-side -k $stack_examples_path/kustomize/multi-operator/bases/crd
kubectl create ns control-plane
kubectl apply --server-side -k $stack_examples_path/kustomize/multi-operator/install-ctl-plane/default/

# install data-plane1
kubectl config use-context data-plane1
kubectl apply --server-side -k $stack_examples_path/kustomize/mogdb-operator/bases/crd
kustomization="$stack_examples_path/kustomize/mogdb-operator/install/singlenamespace/kustomization.yaml"
leader_election_role_binding="$stack_examples_path/kustomize/mogdb-operator/install/singlenamespace/patches/rbac/leader_election_role_binding.yaml"
leader_election_role="$stack_examples_path/kustomize/mogdb-operator/install/singlenamespace/patches/rbac/leader_election_role.yaml"
manager_role_binding="$stack_examples_path/kustomize/mogdb-operator/install/singlenamespace/patches/rbac/manager_role_binding.yaml"
manager_role="$stack_examples_path/kustomize/mogdb-operator/install/singlenamespace/patches/rbac/manager_role.yaml"
grep "namespace:" $kustomization | xargs -I '{}' sed -i 's/{}/namespace: data-plane1/g' $kustomization
grep "value:" $leader_election_role_binding | xargs -I '{}' sed -i 's/{}/value: mogdb-operator-system-leader-election-rolebinding-data-plane1/g' $leader_election_role_binding
grep "value:" $leader_election_role | xargs -I '{}' sed -i 's/{}/value: mogdb-operator-system-leader-election-role-data-plane1/g' $leader_election_role
grep "value:" $manager_role_binding | xargs -I '{}' sed -i 's/{}/value: mogdb-operator-system-manager-rolebinding-data-plane1/g' $manager_role_binding
grep "value:" $manager_role | xargs -I '{}' sed -i 's/{}/value: mogdb-operator-system-manager-role-data-plane1/g' $manager_role
kubectl create ns data-plane1
kubectl apply --server-side -k $stack_examples_path/kustomize/mogdb-operator/install/singlenamespace/

# install data-plane2
kubectl config use-context data-plane2
kubectl apply --server-side -k $stack_examples_path/kustomize/mogdb-operator/bases/crd
grep "namespace:" $kustomization | xargs -I '{}' sed -i 's/{}/namespace: data-plane2/g' $kustomization
grep "value:" $leader_election_role_binding | xargs -I '{}' sed -i 's/{}/value: mogdb-operator-system-leader-election-rolebinding-data-plane2/g' $leader_election_role_binding
grep "value:" $leader_election_role | xargs -I '{}' sed -i 's/{}/value: mogdb-operator-system-leader-election-role-data-plane2/g' $leader_election_role
grep "value:" $manager_role_binding | xargs -I '{}' sed -i 's/{}/value: mogdb-operator-system-manager-rolebinding-data-plane2/g' $manager_role_binding
grep "value:" $manager_role | xargs -I '{}' sed -i 's/{}/value: mogdb-operator-system-manager-role-data-plane2/g' $manager_role
kubectl create ns data-plane2
kubectl apply --server-side -k $stack_examples_path/kustomize/mogdb-operator/install/singlenamespace/

# regist data-plane to control-plane
bash $stack_examples_path/join-to-control-plane.sh \
--src-namespace data-plane1 \
--src-serviceaccount mogdb-operator-controller-manager \
--src-context data-plane1 \
--src-kubeconfig ~/.kube/config \
--dest-context control-plane \
--dest-kubeconfig ~/.kube/config \
--dest-namespace control-plane
bash $stack_examples_path/join-to-control-plane.sh \
--src-namespace data-plane2 \
--src-serviceaccount mogdb-operator-controller-manager \
--src-context data-plane2 \
--src-kubeconfig ~/.kube/config \
--dest-context control-plane \
--dest-kubeconfig ~/.kube/config \
--dest-namespace control-plane

# install multi-cluster
kubectl create ns mogdb-operator-system
kubectl apply --server-side -k $stack_examples_path/kustomize/multi-cluster/install/default
kubectl get pods -A
# kubectl delete -k kustomize/multi-cluster/install/default
# kubectl apply --server-side -k kustomize/multi-cluster/install/default