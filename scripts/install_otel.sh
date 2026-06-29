#!/bin/bash
################################################################################
# install_otel.sh
#
# Installs OpenTelemetry Collector Contrib
# Amazon Linux 2023
################################################################################

set -euo pipefail

################################################################################
# Load Common Functions
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

require_root

log_header "Installing OpenTelemetry Collector"

################################################################################
# Variables
################################################################################

OTEL_VERSION="0.129.1"

OTEL_USER="otel"

OTEL_GROUP="otel"

OTEL_BINARY="/usr/local/bin/otelcol-contrib"

OTEL_CONFIG="/etc/otel/otelcol.yaml"

OTEL_HOME="/var/lib/otel"

################################################################################
# Create User
################################################################################

create_system_user "${OTEL_USER}"

################################################################################
# Create Directories
################################################################################

create_dir "/etc/otel" "${OTEL_USER}" "${OTEL_GROUP}"

create_dir "${OTEL_HOME}" "${OTEL_USER}" "${OTEL_GROUP}"

################################################################################
# Download Collector
################################################################################

log_info "Downloading OpenTelemetry Collector ${OTEL_VERSION}"

cd /tmp

wget -q \
https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz

rm -rf otel-download

mkdir otel-download

tar -xzf otelcol-contrib_${OTEL_VERSION}_linux_amd64.tar.gz \
-C otel-download

install -m755 otel-download/otelcol-contrib "${OTEL_BINARY}"

################################################################################
# Configuration
################################################################################

cat > "${OTEL_CONFIG}" <<EOF
receivers:

  otlp:
    protocols:
      grpc:
      http:

processors:

  batch:

exporters:

  otlp:
    endpoint: localhost:4317
    tls:
      insecure: true

  debug:

service:

  pipelines:

    traces:

      receivers: [otlp]

      processors: [batch]

      exporters: [otlp,debug]
EOF

################################################################################
# Permissions
################################################################################

chown "${OTEL_USER}:${OTEL_GROUP}" "${OTEL_CONFIG}"

################################################################################
# Systemd Service
################################################################################

cat >/etc/systemd/system/otelcol.service <<EOF
[Unit]
Description=OpenTelemetry Collector
Documentation=https://opentelemetry.io/
After=network-online.target

[Service]

User=${OTEL_USER}
Group=${OTEL_GROUP}

ExecStart=${OTEL_BINARY} \
--config=${OTEL_CONFIG}

Restart=always
RestartSec=5

LimitNOFILE=65536

WorkingDirectory=${OTEL_HOME}

[Install]
WantedBy=multi-user.target
EOF

################################################################################
# Enable Service
################################################################################

enable_service otelcol

################################################################################
# Start Service
################################################################################

start_service otelcol

################################################################################
# Wait
################################################################################

if wait_for_service otelcol; then

    log_success "OpenTelemetry Collector started."

else

    journalctl -u otelcol --no-pager -n 50

    fatal "OpenTelemetry Collector failed."

fi

################################################################################
# Version
################################################################################

echo
echo "Installed Version:"
"${OTEL_BINARY}" --version

################################################################################
# Finish
################################################################################

log_success "OpenTelemetry Collector installation completed."
