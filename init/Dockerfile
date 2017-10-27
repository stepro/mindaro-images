FROM alpine
RUN apk add --no-cache iptables
COPY init.sh /
RUN chmod +x /init.sh
ENTRYPOINT [ "/init.sh" ]