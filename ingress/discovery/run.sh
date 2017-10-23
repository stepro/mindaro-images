#!/bin/sh

cd /usr/share/nginx

mkdir -p html/v1/clusters/cluster

update() {
    kubectl get --all-namespaces service -o go-template-file=clusters.json.tmpl > html/v1/clusters/cluster/node
}

update

watch() {
  kubectl get --all-namespaces service --watch-only -o go-template='
' | while read empty; do
    update
  done
}

watch &

exec "$@"
