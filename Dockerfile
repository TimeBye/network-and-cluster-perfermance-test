FROM alpine:3.8

RUN mkdir -p /data \
    && apk add --no-cache bash curl iperf ca-certificates bind-tools
COPY curl.sh /usr/bin/curls
VOLUME ["/data"]