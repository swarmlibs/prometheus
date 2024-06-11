# About

The Prometheus monitoring system and time series database customized for Docker Swarm.

## Goals

- A standard metrics labeling for Docker Swarm compatible scrape configs (i.e. nodes, services and tasks).
- Provide a Kubernetes compatible labels, this grant us the ability to reuse some of the already existing Grafana Dashboard already built for Kubernetes.

## References

- https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- https://grafana.com/blog/2022/03/21/how-relabeling-in-prometheus-works/#available-actions
- https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus-dockerswarm.yml
- https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus-kubernetes.yml
