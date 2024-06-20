ARG ALPINE_VERSION=latest
ARG PROMETHEUS_VERSION=v2.44.0
FROM prom/prometheus:$PROMETHEUS_VERSION AS prometheusbin

FROM alpine:$ALPINE_VERSION

# Recreate original prometheus image
COPY --from=prometheusbin /bin/prometheus /bin/prometheus
COPY --from=prometheusbin /bin/promtool /bin/promtool
COPY --from=prometheusbin /usr/share/prometheus/console_libraries/ /usr/share/prometheus/console_libraries/
COPY --from=prometheusbin /usr/share/prometheus/consoles/ /usr/share/prometheus/consoles/
COPY --from=prometheusbin /LICENSE /LICENSE
COPY --from=prometheusbin /NOTICE /NOTICE
COPY --from=prometheusbin /npm_licenses.tar.bz2 /npm_licenses.tar.bz2
# RUN ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/ && \
#     chown -R nobody:nobody /etc/prometheus /prometheus
EXPOSE 9090/tcp
VOLUME /prometheus/data

RUN apk add --no-cache bash ca-certificates uuidgen
ADD rootfs /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
VOLUME [ "/prometheus/data", "/prometheus-configs.d" ]
