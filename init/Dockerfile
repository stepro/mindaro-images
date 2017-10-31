FROM alpine
WORKDIR /usr/local/bin
RUN apk add --no-cache curl iptables \
 && curl -fSL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o kubectl && chmod +x kubectl \
 && apk del curl
COPY init.sh .
RUN chmod +x init.sh
ENTRYPOINT [ "init.sh" ]