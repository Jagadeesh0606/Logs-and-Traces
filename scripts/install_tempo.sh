#!/bin/bash
################################################################################
# install_tempo.sh
#
# Installs Grafana Tempo on Amazon Linux 2023
################################################################################

set -euo pipefail

################################################################################
# Load Common Functions
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

require_root

log_header "Installing Grafana Tempo"

################################################################################
# Variables
################################################################################

TEMPO_VERSION="2.8.2"

TEMPO_USER="tempo"

TEMPO_GROUP="tempo"

TEMPO_BINARY="/usr/local/bin/tempo"

TEMPO_CONFIG="/etc/tempo/tempo.yaml"

TEMPO_HOME="/var/lib/tempo"

################################################################################
# Create User
################################################################################

create_system_user "${TEMPO_USER}"

################################################################################
# Create Directories
################################################################################

create_dir "/etc/tempo" "${TEMPO_USER}" "${TEMPO_GROUP}"

create_dir "${TEMPO_HOME}" "${TEMPO_USER}" "${TEMPO_GROUP}"

create_dir "${TEMPO_HOME}/traces" "${TEMPO_USER}" "${TEMPO_GROUP}"

################################################################################
# Download Tempo
################################################################################

log_info "Downloading Tempo ${TEMPO_VERSION}..."

cd /tmp

wget -q \
https://github.com/grafana/tempo/releases/download/v${TEMPO_VERSION}/tempo_${TEMPO_VERSION}_linux_amd64.tar.gz

rm -rf tempo-download

mkdir tempo-download

tar -xzf tempo_${TEMPO_VERSION}_linux_amd64.tar.gz \
-C tempo-download

install -m755 tempo-download/tempo "${TEMPO_BINARY}"

################################################################################
# Configuration
################################################################################

cat > "${TEMPO_CONFIG}" <<EOF
server:
  http_listen_port: 3200
  grpc_listen_port: 9096

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
        http:

ingester:
  trace_idle_period: 10s
  max_block_duration: 5m

compactor:
  compaction:
    block_retention: 24h

storage:
  trace:
    backend: local
    local:
      path: ${TEMPO_HOME}/traces

metrics_generator:
  registry:
    external_labels:
      source: tempo

overrides:
  defaults:
    metrics_generator:
      processors: [service-graphs, span-metrics]
EOF

################################################################################
# Permissions
################################################################################

chown "${TEMPO_USER}:${TEMPO_GROUP}" "${TEMPO_CONFIG}"

################################################################################
# Systemd Service
################################################################################

cat >/etc/systemd/system/tempo.service <<EOF
[Unit]
Description=Grafana Tempo
Documentation=https://grafana.com/docs/tempo/
After=network-online.target

[Service]
User=${TEMPO_USER}
Group=${TEMPO_GROUP}

ExecStart=${TEMPO_BINARY} --config.file=${TEMPO_CONFIG}

Restart=always
RestartSec=5

LimitNOFILE=65536

WorkingDirectory=${TEMPO_HOME}

[Install]
WantedBy=multi-user.target
EOF

################################################################################
# Enable
################################################################################

enable_service tempo

################################################################################
# Start
################################################################################

start_service tempo

################################################################################
# Wait
################################################################################

if wait_for_service tempo; then

    log_success "Tempo service started."

else

    journalctl -u tempo --no-pager -n 50

    fatal "Tempo failed to start."

fi

################################################################################
# HTTP Health Check
################################################################################

if wait_for_http "http://localhost:3200/ready"; then

    log_success "Tempo HTTP endpoint is ready."

else

    fatal "Tempo readiness check failed."

fi

################################################################################
# Version
################################################################################

echo
echo "Installed Version:"
"${TEMPO_BINARY}" --version || true

################################################################################
# Finished
################################################################################

log_success "Grafana Tempo installation completed."
