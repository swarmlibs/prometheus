#!/bin/bash
# Copyright (c) Swarm Library Maintainers.
# SPDX-License-Identifier: MIT

set -e

# Docker Swarm service template variables
#  - DOCKERSWARM_SERVICE_ID={{.Service.ID}}
#  - DOCKERSWARM_SERVICE_NAME={{.Service.Name}}
#  - DOCKERSWARM_NODE_ID={{.Node.ID}}
#  - DOCKERSWARM_NODE_HOSTNAME={{.Node.Hostname}}
#  - DOCKERSWARM_TASK_ID={{.Task.ID}}
#  - DOCKERSWARM_TASK_NAME={{.Task.Name}}
#  - DOCKERSWARM_TASK_SLOT={{.Task.Slot}}
#  - DOCKERSWARM_STACK_NAMESPACE={{ index .Service.Labels "com.docker.stack.namespace"}}
export DOCKERSWARM_SERVICE_ID=${DOCKERSWARM_SERVICE_ID}
export DOCKERSWARM_SERVICE_NAME=${DOCKERSWARM_SERVICE_NAME}
export DOCKERSWARM_NODE_ID=${DOCKERSWARM_NODE_ID}
export DOCKERSWARM_NODE_HOSTNAME=${DOCKERSWARM_NODE_HOSTNAME}
export DOCKERSWARM_TASK_ID=${DOCKERSWARM_TASK_ID}
export DOCKERSWARM_TASK_NAME=${DOCKERSWARM_TASK_NAME}
export DOCKERSWARM_TASK_SLOT=${DOCKERSWARM_TASK_SLOT}
export DOCKERSWARM_STACK_NAMESPACE=${DOCKERSWARM_STACK_NAMESPACE}

# Check if any of the variables is empty
if [ -z "$DOCKERSWARM_SERVICE_ID" ] || [ -z "$DOCKERSWARM_SERVICE_NAME" ] || [ -z "$DOCKERSWARM_NODE_ID" ] || [ -z "$DOCKERSWARM_NODE_HOSTNAME" ] || [ -z "$DOCKERSWARM_TASK_ID" ] || [ -z "$DOCKERSWARM_TASK_NAME" ] || [ -z "$DOCKERSWARM_TASK_SLOT" ] || [ -z "$DOCKERSWARM_STACK_NAMESPACE" ]; then
  echo "==> Docker Swarm service template variables:"
  echo "- DOCKERSWARM_SERVICE_ID=${DOCKERSWARM_SERVICE_ID}"
  echo "- DOCKERSWARM_SERVICE_NAME=${DOCKERSWARM_SERVICE_NAME}"
  echo "- DOCKERSWARM_NODE_ID=${DOCKERSWARM_NODE_ID}"
  echo "- DOCKERSWARM_NODE_HOSTNAME=${DOCKERSWARM_NODE_HOSTNAME}"
  echo "- DOCKERSWARM_TASK_ID=${DOCKERSWARM_TASK_ID}"
  echo "- DOCKERSWARM_TASK_NAME=${DOCKERSWARM_TASK_NAME}"
  echo "- DOCKERSWARM_TASK_SLOT=${DOCKERSWARM_TASK_SLOT}"
  echo "- DOCKERSWARM_STACK_NAMESPACE=${DOCKERSWARM_STACK_NAMESPACE}"
  echo "One or more variables is empty. Exiting..."
  exit 1
fi

# Prometheus configuration file.
PROMETHEUS_TSDB_PATH=${PROMETHEUS_TSDB_PATH:-"/prometheus/data"}
PROMETHEUS_CONFIG_FILE=${PROMETHEUS_CONFIG_FILE:-"/etc/prometheus/prometheus.yml"}

# Create the directory for the configuration parts.
mkdir -p $(dirname ${PROMETHEUS_CONFIG_FILE})

# Generate a random node ID which will be persisted in the data directory
if [ ! -f "${PROMETHEUS_TSDB_PATH}/node-id" ]; then
    echo "==> Generate a random node ID which will be persisted in the data directory..."
    uuidgen > "${PROMETHEUS_TSDB_PATH}/node-id"
fi

# Set the PROMETHEUS_NODE_ID to the content of the node-id file
PROMETHEUS_NODE_ID=$(cat "${PROMETHEUS_TSDB_PATH}/node-id")

# External labels
PROMETHEUS_CLUSTER_NAME=${PROMETHEUS_CLUSTER_NAME:-${DOCKERSWARM_STACK_NAMESPACE:-"default"}}
echo "==> Configure PROMETHEUS_CLUSTER_NAME as \"${PROMETHEUS_CLUSTER_NAME}\""

PROMETHEUS_CLUSTER_REPLICA=${PROMETHEUS_CLUSTER_REPLICA:-${DOCKERSWARM_NODE_ID:-${PROMETHEUS_NODE_ID}}}
echo "==> Configure PROMETHEUS_CLUSTER_REPLICA as \"${PROMETHEUS_CLUSTER_REPLICA}\""

# Generate the global configuration file.
PROMETHEUS_SCRAPE_INTERVAL=${PROMETHEUS_SCRAPE_INTERVAL:-"10s"}
PROMETHEUS_SCRAPE_TIMEOUT=${PROMETHEUS_SCRAPE_TIMEOUT:-"5s"}
PROMETHEUS_EVALUATION_INTERVAL=${PROMETHEUS_EVALUATION_INTERVAL:-"1m"}

# Prometheus dynamic scrape configuration directory
PROMETHEUS_DYNAMIC_SRAPE_CONFIG_DIR=${PROMETHEUS_DYNAMIC_SRAPE_CONFIG_DIR:-"/prometheus-configs.d"}

# Alertmanager configuration
PROMETHEUS_ALERTMANAGER_SERVICE_NAME=${PROMETHEUS_ALERTMANAGER_SERVICE_NAME:-"alertmanager"}
PROMETHEUS_ALERTMANAGER_SERVICE_PORT=${PROMETHEUS_ALERTMANAGER_SERVICE_PORT:-"9093"}

echo "==> Generating the global configuration file..."
cat <<EOF > "${PROMETHEUS_CONFIG_FILE}"
# A scrape configuration for running Prometheus on a Docker Swarm cluster.
# This uses separate scrape configs for cluster components (i.e. nodes, services, tasks).
# 
# Keep at most 50 sets of details of targets dropped by relabeling.
# This information is used to display in the UI for troubleshooting.
global:
  scrape_interval: ${PROMETHEUS_SCRAPE_INTERVAL} # Set the scrape interval to every ${PROMETHEUS_SCRAPE_INTERVAL}. Default is every 5s. Prometheus default is 1 minute.
  scrape_timeout: ${PROMETHEUS_SCRAPE_TIMEOUT} # scrape_timeout is set to the ${PROMETHEUS_SCRAPE_TIMEOUT}. The default is 10s. Prometheus default is 10s.
  evaluation_interval: ${PROMETHEUS_EVALUATION_INTERVAL} # Evaluate rules every ${PROMETHEUS_EVALUATION_INTERVAL}. The default is 1 minute.
  keep_dropped_targets: 50

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    __replica__: '${PROMETHEUS_CLUSTER_REPLICA}'
    cluster: '${PROMETHEUS_CLUSTER_NAME}'

# ====================================================
# Alertmanager configuration
# ====================================================

# Local cluster alertmanager with DNS discovery
alerting:
  alertmanagers:
    - dns_sd_configs:
      - names:
        - 'tasks.${PROMETHEUS_ALERTMANAGER_SERVICE_NAME}'
        type: 'A'
        port: ${PROMETHEUS_ALERTMANAGER_SERVICE_PORT}
        refresh_interval: 30s

  # All alerts sent to the Alertmanager will then also have different replica labels.
  # Since the Alertmanager dedupes alerts based on identical label sets, 
  # this deduplication will now break and you will get as many notifications as you have Prometheus server replicas!
  # To avoid this, make sure that you drop the replica label on the alerting path using alert relabeling:
  alert_relabel_configs:
    - action: labeldrop
      regex: __replica__

# ====================================================
# Scrape configuration
# ====================================================

# Load scrape configs from this directory.
scrape_config_files:
  - "/dockerswarm.d/*"
  - "${PROMETHEUS_DYNAMIC_SRAPE_CONFIG_DIR}/*"

# Make Prometheus scrape itself for metrics.
scrape_configs:
  - job_name: 'prometheus'
    file_sd_configs:
      - files:
        - /etc/prometheus/server.json
EOF

echo "==> Generating the Prometheus self-discovery configuration file..."
cat <<EOF >"/etc/prometheus/server.json"
[
  {
    "targets": [
      "$HOSTNAME:9090"
    ],
    "labels": {
      "dockerswarm_service_id": "${DOCKERSWARM_SERVICE_ID}",
      "dockerswarm_service_name": "${DOCKERSWARM_SERVICE_NAME}",
      "dockerswarm_node_id": "${DOCKERSWARM_NODE_ID}",
      "dockerswarm_node_hostname": "${DOCKERSWARM_NODE_HOSTNAME}",
      "dockerswarm_task_id": "${DOCKERSWARM_TASK_ID}",
      "dockerswarm_task_name": "${DOCKERSWARM_TASK_NAME}",
      "dockerswarm_task_slot": "${DOCKERSWARM_TASK_SLOT}",
      "dockerswarm_stack_namespace": "${DOCKERSWARM_STACK_NAMESPACE}"
    }
  }
]
EOF

# If the user is trying to run Prometheus directly with some arguments, then
# pass them to Prometheus.
if [ "${1:0:1}" = '-' ]; then
    set -- prometheus "$@"
fi

# If the user is trying to run Prometheus directly with out any arguments, then
# pass the configuration file as the first argument.
if [ "$1" = "" ]; then
    set -- prometheus \
        --config.file="${PROMETHEUS_CONFIG_FILE}" \
        --storage.tsdb.path="${PROMETHEUS_TSDB_PATH}" \
        --web.enable-lifecycle \
        --web.console.libraries=/usr/share/prometheus/console_libraries \
        --web.console.templates=/usr/share/prometheus/consoles \
        --log.level=info
fi

echo "==> Starting Prometheus server..."
set -x
exec "$@"
