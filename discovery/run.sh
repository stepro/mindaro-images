#!/bin/sh

mkdir -p /usr/share/nginx/html/v1

update() {
    kubectl get --all-namespaces service -o go-template-file=/usr/share/nginx/listeners.json.tmpl > /usr/share/nginx/html/v1/listeners
    kubectl get --all-namespaces service -o go-template-file=/usr/share/nginx/clusters.json.tmpl > /usr/share/nginx/html/v1/clusters    
}

update

watch() {
  kubectl get --all-namespaces service --watch-only -o go-template='
' | while read empty; do
    update
  done
}

watch &
# PID=$!

# trap "kill $PID; exit 130" INT
# trap "kill $PID; exit 143" TERM

exec "$@"
# wait $PID
