ARG ALPINE_VERSION=latest
ARG PROMETHEUS_VERSION=v2.44.0
ARG GOMPLATE_VERSION=alpine

FROM prom/prometheus:$PROMETHEUS_VERSION AS prometheus
FROM hairyhenderson/gomplate:$GOMPLATE_VERSION AS gomplate

FROM alpine:$ALPINE_VERSION

# Recreate original prometheus image
COPY --from=prometheus /bin/prometheus /bin/prometheus
COPY --from=prometheus /bin/promtool /bin/promtool
COPY --from=prometheus /usr/share/prometheus/console_libraries/ /usr/share/prometheus/console_libraries/
COPY --from=prometheus /usr/share/prometheus/consoles/ /usr/share/prometheus/consoles/
COPY --from=prometheus /LICENSE /LICENSE
COPY --from=prometheus /NOTICE /NOTICE
COPY --from=prometheus /npm_licenses.tar.bz2 /npm_licenses.tar.bz2
# RUN ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/ && \
#     chown -R nobody:nobody /etc/prometheus /prometheus
EXPOSE 9090/tcp
VOLUME /prometheus/data

COPY --from=gomplate /bin/gomplate /bin/gomplate
RUN apk add --no-cache bash ca-certificates uuidgen
ADD rootfs /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
VOLUME [ "/prometheus/data", "/prometheus-configs.d" ]
