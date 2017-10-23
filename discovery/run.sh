#!/bin/sh

if [ -z "$POD_NAME" ]; then
    echo >&2 error: must specify POD_NAME environment variable
    exit 1
fi

cd /usr/share/nginx

cat << EOF > listeners.json.tmpl
{
    "listeners": [
        {
            "name": "0.0.0.0:15001",
            "address": "tcp://0.0.0.0:15001",
            "filters": [],
            "use_original_dst": true
        }$(kubectl get pod $POD_NAME -o go-template-file=listeners.in.json.tmpl)
$(cat listeners.out.json.tmpl)
    ]
}
EOF

cat << EOF > clusters.json.tmpl
{
    "clusters": [$(kubectl get pod $POD_NAME -o go-template-file=clusters.in.json.tmpl)
$(cat clusters.out.json.tmpl)
    ]
}
EOF

mkdir -p html/v1/listeners/cluster
mkdir -p html/v1/clusters/cluster

update() {
    kubectl get --all-namespaces service -o go-template-file=listeners.json.tmpl > html/v1/listeners/cluster/node
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
