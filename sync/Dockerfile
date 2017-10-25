FROM alpine
WORKDIR /usr/local/bin
RUN apk add --no-cache curl \
 && curl -fSL https://github.com/stepro/dcwatch/releases/download/v0.1.0/dcwatch-linux-amd64 -o dcwatch && chmod +x dcwatch \
 && curl -fSL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o kubectl && chmod +x kubectl \
 && apk del curl

COPY run.sh .
RUN chmod +x run.sh
CMD [ "run.sh" ]