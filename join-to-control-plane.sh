#!/usr/bin/env bash
#
# mogdb-operator should be installed in the remote clusters prior to running this. The
# script fetches the mogdb-operator service account from the remote cluster and
# extracts the token and CA cert which are then added to a kubeconfig file. The script then
# creates a secret with the contents of the kubeconfig file. Lastly, the script creates a
# ClientConfig object that references the secret.
#
# This script requires the following to be installed:
#
#    - kubectl
#
# TODO Accept multiple values for the src-context option and generate a kubeconfig with
#      entries for each

set -e

getopt_version=$(getopt -V)
if [[ "$getopt_version" == " --" ]]; then
  echo "gnu-getopt doesn't seem to be installed. Install it using: brew install gnu-getopt"
  exit 1
fi

OPTS=$(getopt -o h --long src-context:,src-namespace:,src-serviceaccount:,src-kubeconfig:,dest-namespace:,dest-context:,dest-kubeconfig:,output-dir:,help -n 'create-client-config' -- "$@")

eval set -- "$OPTS"

function help() {
cat <<EOF
Syntax: create-client-config.sh [options]
Options:
  --help                          Displays this help message.
  --src-namespace <ns>            The namespace in which the serviceaccount exists.
                                  Defaults to mogdb-operator-system.
  --src-context <ctx>             The context for the source cluster that contains the serviceaccount.
                                  This or the src-kubeconfig option must be set.
  --src-kubeconfig <cfg>          The kubeconfig for the source cluster that contains the serviceaccount.
                                  This or the src-context option must be set.
  --src-serviceaccount <name>     The name of the service account from which the ClientConfig will be created.
                                  Defaults to mogdb-operator-controller-manager.
  --dest-namespace <ns>           The namespace where the ClientConfig will be created.
                                  Defaults to mogdb-operator-system.
  --dest-context <ctx>            The context for the cluster where the ClientConfig will be created.
                                  Defaults to the current context of the kubeconfig used.
  --dest-kubeconfig <cfg>         The kubeconfig for the cluster where the ClientConfig will be created.
                                  Defaults to $HOME/.kube/config.
  --output-dir <path>             The directory where generated artifacts are written. If not specified a temp directory is created.
EOF
}

output_dir=""
src_context=""
src_namespace=""
dest_context=""
dest_namespace=""
src_kubeconfig=""
dest_kubeconfig=""
# namespace="mogdb-operator-system"
service_account="mogdb-operator-controller-manager"

while true; do
  case "$1" in
  --)
    shift
    break
    ;;
  -h | --help)
    help
    exit
    ;;
  --src-namespace)
    src_namespace="$2"
    shift 2
    ;;
  --dest-namespace)
    dest_namespace="$2"
    shift 2
    ;;
  --output-dir)
    output_dir="$2"
    shift 2
    ;;
  --src-context)
    src_context="$2"
    shift 2
    ;;
  --dest-context)
    dest_context="$2"
    shift 2
    ;;
  --src-kubeconfig)
    src_kubeconfig="$2"
    shift 2
    ;;
  --dest-kubeconfig)
    dest_kubeconfig="$2"
    shift 2
    ;;
  --src-serviceaccount)
    service_account="$2"
    shift 2
    ;;
  *) break ;;
  esac
done

if [ -z "$src_context" ] && [ -z "$src_kubeconfig" ]; then
  echo "At least one of the --src-context or --src-kubeconfig options must be specified"
  exit 1
fi

src_namespace_opt=
src_context_opt=""
dest_context_opt=""
dest_namespace_opt=
src_kubeconfig_opt=""
dest_kubeconfig_opt=""

if [ -n "$output_dir" ]; then
  mkdir -p "$output_dir"
else
  output_dir=$(mktemp -d)
fi

if [ -n "$src_namespace" ]; then
  src_namespace_opt="-n $src_namespace"
fi

if [ -n "$dest_namespace" ];then
  dest_namespace_opt="-n $dest_namespace"
fi

if [ -n "$src_kubeconfig" ]; then
  src_kubeconfig_opt="--kubeconfig $src_kubeconfig"
fi

if [ -n "$dest_kubeconfig" ]; then
  dest_kubeconfig_opt="--kubeconfig $dest_kubeconfig"
fi

if [ -z "$src_context" ]; then
  src_context=$(kubectl "$src_kubeconfig_opt" config current-context)
fi

if [ -z "$dest_context" ]; then
  dest_context=$(kubectl "$dest_kubeconfig_opt" config current-context)
fi

src_context_opt="--context $src_context"
dest_context_opt="--context $dest_context"

# create kubeConfig

# get current cluster name
cluster=$(kubectl $src_kubeconfig_opt $src_context_opt config view -o jsonpath="{.contexts[?(@.name == \"$src_context\"})].context.cluster}")
# get current apiserver address
apiserver_addr=$(kubectl $src_kubeconfig_opt $src_context_opt config view -o jsonpath="{.clusters[?(@.name == \"$cluster\"})].cluster.server}")
# apiserver addr has localhost address; replacing it
if [[ $apiserver_addr == *"127.0.0.1"* ]]; then
  apiserver_ip=$(kubectl $src_kubeconfig_opt $src_context_opt -n kube-system get pod -l component=kube-apiserver -o jsonpath='{.items[0].status.podIP}')

  apiserver_addr="https://$apiserver_ip:6443"
  echo "Source cluster had localhost as the API server address; replacing with $apiserver_addr"
fi
# get serviceaccount secret
sa_secret=$(kubectl $src_kubeconfig_opt $src_context_opt $src_namespace_opt get serviceaccount $service_account -o jsonpath='{.secrets[0].name}')
# get crt from serviceaccount secret
sa_cert=$(kubectl $src_kubeconfig_opt $src_context_opt $src_namespace_opt get secret $sa_secret -o jsonpath="{.data['ca\.crt']}")
# get token from serviceaccount secret
sa_token=$(kubectl $src_kubeconfig_opt $src_context_opt $src_namespace_opt get secret $sa_secret -o jsonpath='{.data.token}' | base64 -d)
# generate kubeConfig to output dir
kubeconfig_path="$output_dir/kubeconfig"
echo "Creating KubeConfig at $kubeconfig_path"
cat >"$kubeconfig_path" <<EOF
apiVersion: v1
kind: Config
preferences: {}
current-context: ${src_namespace}
users:
- name: $cluster-${service_account}
  user:
    token: $sa_token
clusters:
- name: ${cluster}
  cluster:
    server: ${apiserver_addr}
    certificate-authority-data: ${sa_cert}
contexts:
- name: ${src_namespace}
  context:
    cluster: ${cluster}
    user: $cluster-${service_account}
EOF

# create secret to control plane
output_secret=$(echo "$src_namespace" | tr '_' '-')
echo "Creating secret $output_secret"

kubectl $dest_kubeconfig_opt $dest_context_opt $dest_namespace_opt delete secret $output_secret || true
kubectl $dest_kubeconfig_opt $dest_context_opt $dest_namespace_opt create secret generic $output_secret --from-file=$kubeconfig_path

# create client config to control plane
clientconfig_name=$(echo "$src_namespace" | tr '_' '-')
clientconfig_path="${output_dir}/${clientconfig_name}.yaml"
echo "Creating ClientConfig $clientconfig_path"
cat >"$clientconfig_path" <<EOF
apiVersion: mogdb.enmotech.io/v1
kind: KubeClientConfig
metadata:
  name: ${clientconfig_name}
spec:
  contextName: ${src_namespace}
  kubeConfigSecret:
    name: ${output_secret}
    namespace: ${dest_namespace}
EOF

kubectl $dest_kubeconfig_opt $dest_context_opt $dest_namespace_opt apply -f $clientconfig_path
