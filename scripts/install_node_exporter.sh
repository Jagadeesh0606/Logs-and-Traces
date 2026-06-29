#!/bin/bash
################################################################################
# install_node_exporter.sh
#
# Installs Prometheus Node Exporter
# Amazon Linux 2023
################################################################################

set -euo pipefail

################################################################################
# Load Common Functions
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

require_root

log_header "Installing Node Exporter"

################################################################################
# Variables
################################################################################

NODE_EXPORTER_VERSION="1.9.1"

NODE_USER="node_exporter"

NODE_GROUP="node_exporter"

NODE_BINARY="/usr/local/bin/node_exporter"

################################################################################
# Create User
################################################################################

create_system_user "${NODE_USER}"

################################################################################
# Create Directories
################################################################################

create_dir "/etc/node_exporter" "${NODE_USER}" "${NODE_GROUP}"

create_dir "/var/lib/node_exporter" "${NODE_USER}" "${NODE_GROUP}"

################################################################################
# Download
################################################################################

log_info "Downloading Node Exporter ${NODE_EXPORTER_VERSION}"

cd /tmp

wget -q \
https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

rm -rf node_exporter-download

mkdir node_exporter-download

tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz \
-C node_exporter-download

install -m755 \
node_exporter-download/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter \
"${NODE_BINARY}"

################################################################################
# systemd Service
################################################################################

cat >/etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target

[Service]

User=${NODE_USER}
Group=${NODE_GROUP}

Type=simple

ExecStart=${NODE_BINARY} \
    --collector.systemd \
    --collector.processes \
    --collector.filesystem \
    --collector.cpu \
    --collector.meminfo \
    --collector.netdev \
    --collector.diskstats

Restart=always
RestartSec=5

NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

################################################################################
# Enable
################################################################################

enable_service node_exporter

################################################################################
# Start
################################################################################

start_service node_exporter

################################################################################
# Wait
################################################################################

if wait_for_service node_exporter; then

    log_success "Node Exporter service started."

else

    journalctl -u node_exporter --no-pager -n 50

    fatal "Node Exporter failed."

fi

################################################################################
# HTTP Health
################################################################################

if wait_for_http "http://localhost:9100/metrics"; then

    log_success "Node Exporter metrics endpoint available."

else

    fatal "Node Exporter HTTP endpoint failed."

fi

################################################################################
# Version
################################################################################

echo

echo "Installed Version"

"${NODE_BINARY}" --version

################################################################################
# Finish
################################################################################

log_success "Node Exporter installation completed."
