#!/bin/bash
# Copyright (c) Swarm Library Maintainers.
# SPDX-License-Identifier: MIT

set -e

# Docker Swarm service template variables
#  - DOCKERSWARM_NODE_ID={{.Node.ID}}
#  - DOCKERSWARM_STACK_NAMESPACE={{ index .Service.Labels "com.docker.stack.namespace"}}
DOCKERSWARM_NODE_ID=${DOCKERSWARM_NODE_ID}
DOCKERSWARM_STACK_NAMESPACE=${DOCKERSWARM_STACK_NAMESPACE}

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
PROMETHEUS_SCRAPE_INTERVAL=${PROMETHEUS_SCRAPE_INTERVAL:-"30s"}
PROMETHEUS_SCRAPE_TIMEOUT=${PROMETHEUS_SCRAPE_TIMEOUT:-"15s"}
PROMETHEUS_EVALUATION_INTERVAL=${PROMETHEUS_EVALUATION_INTERVAL:-"15s"}

echo "==> Generating the global configuration file..."
cat <<EOF > "${PROMETHEUS_CONFIG_FILE}"
# A scrape configuration for running Prometheus on a Docker Swarm cluster.
# This uses separate scrape configs for cluster components (i.e. nodes, services, tasks).
# 
# Keep at most 50 sets of details of targets dropped by relabeling.
# This information is used to display in the UI for troubleshooting.
global:
  scrape_interval: ${PROMETHEUS_SCRAPE_INTERVAL} # Set the scrape interval to every ${PROMETHEUS_SCRAPE_INTERVAL}. Default is every 30s. Prometheus default is 1 minute.
  scrape_timeout: ${PROMETHEUS_SCRAPE_TIMEOUT} # scrape_timeout is set to the ${PROMETHEUS_SCRAPE_TIMEOUT}. The default is 15s. Prometheus default is 10s.
  evaluation_interval: ${PROMETHEUS_EVALUATION_INTERVAL} # Evaluate rules every ${PROMETHEUS_EVALUATION_INTERVAL}. The default is every 15s. Prometheus default is 1 minute.
  keep_dropped_targets: 50

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    __replica__: '${PROMETHEUS_CLUSTER_REPLICA}'
    cluster: '${PROMETHEUS_CLUSTER_NAME}'

# Load scrape configs from this directory.
scrape_config_files:
  - "/dockerswarm/*"
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
        --web.console.libraries=/usr/share/prometheus/console_libraries \
        --web.console.templates=/usr/share/prometheus/consoles \
        --log.level=info
fi

echo "==> Starting Prometheus server..."
set -x
exec "$@"
