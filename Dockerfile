FROM alpine:latest

RUN apk add --no-cache esh shellcheck bash yq

COPY check.sh /usr/local/bin/check.sh

RUN chmod +x /usr/local/bin/check.sh

ENTRYPOINT ["/usr/local/bin/check.sh"]
