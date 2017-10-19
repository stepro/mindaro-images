#!/bin/sh

if [ -z "$POD_NAME" ]; then
    echo >&2 error: must specify POD_NAME environment variable
    exit 1
fi

kubectl get pod $POD_NAME -o go-template-file=/etc/envoy.json.tmpl > /tmp/envoy.json

exec envoy -c /tmp/envoy.json
