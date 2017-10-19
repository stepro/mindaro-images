#!/bin/sh

ENVOY_OUTBOUND_CIDR=${ENVOY_OUTBOUND_CIDR:-10.0.0.0/16}
ENVOY_PORT=${ENVOY_PORT:-15001}
ENVOY_UID=${ENVOY_UID:-1337}

# Create a chain for redirecting inbound and outbound traffic through Envoy
iptables -t nat -N ENVOY_REDIRECT \
  -m comment --comment "envoy/redirect-common-chain"
iptables -t nat -A ENVOY_REDIRECT -p tcp -j REDIRECT --to-port $ENVOY_PORT \
  -m comment --comment "envoy/redirect-to-envoy-port"

# Redirect all inbound traffic through Envoy
iptables -t nat -A PREROUTING -j ENVOY_REDIRECT \
  -m comment --comment "envoy/install-envoy-prerouting"

# Create a chain for selectively redirecting outbound traffic through Envoy
iptables -t nat -N ENVOY_OUTPUT \
  -m comment --comment "envoy/common-output-chain"

# Jump to the ENVOY_OUTPUT chain from the OUTPUT chain for all tcp traffic
iptables -t nat -A OUTPUT -p tcp -j ENVOY_OUTPUT \
  -m comment --comment "envoy/install-envoy-output"

# Redirect outbound traffic on the loopback interface through Envoy
iptables -t nat -A ENVOY_OUTPUT -o lo ! -d 127.0.0.1/32 -j ENVOY_REDIRECT \
  -m comment --comment "envoy/redirect-implicit-loopback"

# Do not redirect outbound traffic from Envoy back through Envoy
iptables -t nat -A ENVOY_OUTPUT -m owner --uid-owner $ENVOY_UID -j RETURN \
  -m comment --comment "envoy/bypass-envoy"

# Do not redirect outbound traffic to 127.0.0.1 (localhost)
iptables -t nat -A ENVOY_OUTPUT -d 127.0.0.1/32 -j RETURN \
  -m comment --comment "envoy/bypass-explicit-loopback"

# Do not redirect outbound traffic to the Kubernetes proxy (10.0.0.1)
iptables -t nat -A ENVOY_OUTPUT -d 10.0.0.1/32 -j RETURN \
  -m comment --comment "envoy/bypass-kubernetes-proxy"

# Redirect outbound traffic to internal services through Envoy
iptables -t nat -A ENVOY_OUTPUT -d 10.0.0.0/16 -j ENVOY_REDIRECT \
  -m comment --comment "envoy/redirect-ip-range-10.0.0.0/16"

# Do not redirect any remaining traffic through Envoy
iptables -t nat -A ENVOY_OUTPUT -j RETURN \
  -m comment --comment "envoy/bypass-default-outbound"

# Configure pod's baseline namespace if supplied
if [ -n "$POD_BASELINE_NAMESPACE" ]; then
  sed 's/ svc.cluster.local / '$POD_BASELINE_NAMESPACE'.svc.cluster.local svc.cluster.local /' /etc/resolv.conf > /etc/resolv.conf.new
  cat /etc/resolv.conf.new > /etc/resolv.conf
fi