#!/bin/sh

if [ -z "$POD_NAME" ]; then
    echo >&2 error: must specify POD_NAME environment variable
    exit 1
fi

cd /usr/share/nginx

mkdir -p html/v1/listeners/cluster
mkdir -p html/v1/clusters/cluster

update() {
    kubectl get --all-namespaces service -o go-template-file=listeners.json.tmpl > html/v1/listeners/cluster/node
    kubectl get --all-namespaces ingress -o go-template-file=clusters.json.tmpl > html/v1/clusters/cluster/node
}

update

watch() {
  kubectl get --all-namespaces $1 --watch-only -o go-template='
' | while read empty; do
    update
  done
}

watch ingress &
watch service &

exec "$@"
