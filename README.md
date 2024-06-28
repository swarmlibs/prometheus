# About

The Prometheus monitoring system and time series database customized for Docker Swarm.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/swarmlibs/prometheus/assets/4363857/de6989e9-4a01-4a51-929a-677093c4a07f">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/swarmlibs/prometheus/assets/4363857/935760e1-7493-40d0-acd7-8abae1b7ced8">
  <img src="https://github.com/swarmlibs/prometheus/assets/4363857/935760e1-7493-40d0-acd7-8abae1b7ced8">
</picture>


## Goals

- A standard metrics labeling for Docker Swarm compatible scrape configs (i.e. nodes, services and tasks).
- Provide a Kubernetes compatible labels, this grant us the ability to reuse some of the already existing Grafana Dashboard already built for Kubernetes.

## Features

- Automatically discover and scrape the metrics from the Docker Swarm nodes, services and tasks.
- Ability to configure scrape target via Docker object labels.
- Dynamically inject scrape configs from Docker configs.
- Automatically reload the Prometheus configuration when the Docker configs are create/update/remove.

The dynamic scrape configs are provided by the [swarmlibs/prometheus-configs-provider](https://github.com/swarmlibs/prometheus-configs-provider) service. And with the help of the [prometheus-operator/prometheus-operator/tree/main/cmd/prometheus-config-reloader](https://github.com/prometheus-operator/prometheus-operator/tree/main/cmd/prometheus-config-reloader) tool, we can automatically reload the Prometheus configuration when the Docker configs are create/update/remove.

## Deployment

Please visit [swarmlibs/promstack](https://github.com/swarmlibs/promstack) for the deployment instructions.

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

## Prometheus Kubernetes compatible labels

Here is a list of Docker Service/Task labels that are mapped to Kubernetes labels.

| Kubernetes   | Docker                                                        | Scrape config                  |
| ------------ | ------------------------------------------------------------- | ------------------------------ |
| `namespace`  | `__meta_dockerswarm_service_label_com_docker_stack_namespace` |                                |
| `deployment` | `__meta_dockerswarm_service_name`                             |                                |
| `pod`        | `dockerswarm_task_name`                                       | `promstack/tasks`              |
| `service`    | `__meta_dockerswarm_service_name`                             | `promstack/services-endpoints` |

* **dockerswarm_task_name**: A combination of the service name, slot and task id.

## References

- https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- https://grafana.com/blog/2022/03/21/how-relabeling-in-prometheus-works/#available-actions
- https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus-dockerswarm.yml
- https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus-kubernetes.yml
