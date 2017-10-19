FROM alpine
RUN apk add --no-cache iptables
WORKDIR /usr/local/bin
COPY init.sh .
RUN chmod +x init.sh
ENTRYPOINT [ "./init.sh" ]