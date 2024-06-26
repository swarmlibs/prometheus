# About

The Prometheus monitoring system and time series database customized for Docker Swarm.

## Goals

- A standard metrics labeling for Docker Swarm compatible scrape configs (i.e. nodes, services and tasks).
- Provide a Kubernetes compatible labels, this grant us the ability to reuse some of the already existing Grafana Dashboard already built for Kubernetes.

## Deployment

> WIP

## How to use

By design, the Prometheus server is configured to automatically discover and scrape the metrics from the Docker Swarm nodes, services and tasks.
You can use Docker object labels in the `deploy` block to automagically register services as targets for Prometheus.

- `io.prometheus.enabled`: Enable the Prometheus scraping for the service.
- `io.prometheus.job_name`: The Prometheus job name. Default is `<docker_stack_namespace>/<service_name|job_name>`.
- `io.prometheus.scrape_scheme`: The scheme to scrape the metrics. Default is `http`.
- `io.prometheus.scrape_port`: The port to scrape the metrics. Default is `80`.
- `io.prometheus.metrics_path`: The path to scrape the metrics. Default is `/metrics`.
- `io.prometheus.param_<name>`: The Prometheus scrape parameters.

**Example:**

```yaml
# Annotations:
services:
  my-app:
    # ...
    networks:
      prometheus:
    deploy:
      # ...
      labels:
        io.prometheus.enabled: "true"
        io.prometheus.job_name: "my-app"
        io.prometheus.scrape_port: "8080"

# As limitations of the Docker Swarm, you need to attach the service to the prometheus network.
# This is required to allow the Prometheus server to scrape the metrics.
networks:
  prometheus:
    name: prometheus
    external: true
```

## References

- https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- https://grafana.com/blog/2022/03/21/how-relabeling-in-prometheus-works/#available-actions
- https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus-dockerswarm.yml
- https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus-kubernetes.yml
