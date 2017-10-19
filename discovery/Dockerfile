FROM nginx:alpine

RUN apk add --no-cache curl \
 && curl -fSL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del curl

COPY default.conf /etc/nginx/conf.d
COPY clusters.json.tmpl listeners.json.tmpl /usr/share/nginx/

COPY run.sh /
RUN chmod +x /run.sh

ENTRYPOINT [ "/run.sh" ]
CMD [ "nginx", "-g", "daemon off;" ]