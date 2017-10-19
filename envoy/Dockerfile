FROM lyft/envoy-alpine

RUN apk add --no-cache curl \
 && curl -fSL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del curl

COPY envoy.json.tmpl /etc

COPY start.sh /
RUN chmod +x /start.sh

CMD [ "/start.sh" ]
