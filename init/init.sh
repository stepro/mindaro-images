#!/bin/sh

if [ -z "$POD_NAME" ]; then
  echo >&2 error: must specify POD_NAME environment variable
  exit 1
fi

# Configure baseline namespace
if [ -n "$BASELINE_NAMESPACE" ]; then
  sed 's/ svc.cluster.local / '$BASELINE_NAMESPACE'.svc.cluster.local svc.cluster.local /' /etc/resolv.conf > /etc/resolv.conf.new
  cat /etc/resolv.conf.new > /etc/resolv.conf
fi

# Gather Envoy configuration settings
ENVOY_PORT=${ENVOY_PORT:-15001}
ENVOY_UID=${ENVOY_UID:-1337}

# Create a chain for redirecting traffic through Envoy
iptables -t nat -N ENVOY_REDIRECT \
  -m comment --comment "envoy/redirect-chain"
iptables -t nat -A ENVOY_REDIRECT -p tcp -j REDIRECT --to-port $ENVOY_PORT \
  -m comment --comment "envoy/redirect-to-envoy"

# Determine the set of HTTP ports to redirect through Envoy
HTTP_PORTS=$(echo $(kubectl get pod $POD_NAME -o go-template='{{range .spec.containers}}{{range .ports}}{{if eq .protocol "TCP"}}{{.containerPort}} {{end}}{{end}}{{end}}'))
# TODO: do not redirect specified ports through Envoy  
# if [ -n "$NON_HTTP_PORTS" ]; then
# fi

# Redirect inbound traffic on HTTP ports through Envoy
if [ -n "$HTTP_PORTS" ]; then
  iptables -t nat -A PREROUTING -p tcp -m multiport --dports "$HTTP_PORTS" -j ENVOY_REDIRECT \
    -m comment --comment "envoy/redirect-inbound-http"
fi

# Create a chain for redirecting outbound traffic through Envoy
iptables -t nat -N ENVOY_OUTPUT \
  -m comment --comment "envoy/outbound-chain"

# DO NOT redirect outbound traffic from Envoy back through Envoy
iptables -t nat -A ENVOY_OUTPUT -m owner --uid-owner $ENVOY_UID -j RETURN \
  -m comment --comment "envoy/bypass-envoy"

# DO NOT redirect outbound traffic to 127.0.0.1 (localhost) through Envoy
iptables -t nat -A ENVOY_OUTPUT -d 127.0.0.1/32 -j RETURN \
  -m comment --comment "envoy/bypass-explicit-loopback"

# DO NOT redirect outbound traffic to the Kubernetes proxy (10.0.0.1) through Envoy
iptables -t nat -A ENVOY_OUTPUT -d 10.0.0.1/32 -j RETURN \
  -m comment --comment "envoy/bypass-kubernetes-proxy"

# DO redirect outbound traffic to Kubernetes services through Envoy
iptables -t nat -A ENVOY_OUTPUT -d 10.0.0.0/16 -j ENVOY_REDIRECT \
  -m comment --comment "envoy/redirect-outbound-services"

# Jump to the ENVOY_OUTPUT chain from the OUTPUT chain
iptables -t nat -A OUTPUT -p tcp -j ENVOY_OUTPUT \
  -m comment --comment "envoy/process-outbound"
