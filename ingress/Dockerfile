FROM lyft/envoy-alpine
COPY envoy.json /etc
CMD [ "envoy", "--service-cluster", "cluster", "--service-node", "node", "-c", "/etc/envoy.json" ]
