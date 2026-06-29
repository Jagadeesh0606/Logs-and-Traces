#!/bin/bash
################################################################################
# install_loki.sh
#
# Installs Grafana Loki on Amazon Linux 2023
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

LOKI_VERSION="3.5.3"

LOKI_USER="loki"

LOKI_GROUP="loki"

LOKI_HOME="/var/lib/loki"

LOKI_CONFIG="/etc/loki/config.yaml"

LOKI_BINARY="/usr/local/bin/loki"

################################################################################
# Helper Functions
################################################################################

info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

success() {
    echo -e "\e[32m[SUCCESS]\e[0m $1"
}

error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

################################################################################
# Create User
################################################################################

if ! id "${LOKI_USER}" >/dev/null 2>&1; then
    useradd --system \
        --home "${LOKI_HOME}" \
        --shell /sbin/nologin \
        "${LOKI_USER}"
fi

################################################################################
# Create Directories
################################################################################

mkdir -p /etc/loki

mkdir -p ${LOKI_HOME}/{chunks,index,rules,wal}

chown -R ${LOKI_USER}:${LOKI_GROUP} ${LOKI_HOME}

################################################################################
# Download Loki
################################################################################

info "Downloading Loki ${LOKI_VERSION}..."

cd /tmp

wget -q \
https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip

unzip -o loki-linux-amd64.zip

mv loki-linux-amd64 ${LOKI_BINARY}

chmod +x ${LOKI_BINARY}

################################################################################
# Loki Configuration
################################################################################

cat > ${LOKI_CONFIG} <<EOF
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: ${LOKI_HOME}

  storage:
    filesystem:
      chunks_directory: ${LOKI_HOME}/chunks
      rules_directory: ${LOKI_HOME}/rules

  replication_factor: 1

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  filesystem:
    directory: ${LOKI_HOME}/chunks

limits_config:
  allow_structured_metadata: false

analytics:
  reporting_enabled: false
EOF

################################################################################
# Permissions
################################################################################

chown ${LOKI_USER}:${LOKI_GROUP} ${LOKI_CONFIG}

################################################################################
# systemd Service
################################################################################

cat >/etc/systemd/system/loki.service <<EOF
[Unit]
Description=Grafana Loki
Documentation=https://grafana.com
After=network-online.target

[Service]
User=${LOKI_USER}
Group=${LOKI_GROUP}

ExecStart=${LOKI_BINARY} --config.file=${LOKI_CONFIG}

Restart=always
RestartSec=5

LimitNOFILE=65536

WorkingDirectory=${LOKI_HOME}

[Install]
WantedBy=multi-user.target
EOF

################################################################################
# Enable Service
################################################################################

systemctl daemon-reload

systemctl enable loki

################################################################################
# Start Service
################################################################################

systemctl restart loki

sleep 5

################################################################################
# Verify Service
################################################################################

if systemctl is-active --quiet loki; then
    success "Loki service started."
else
    error "Loki failed."

    journalctl -u loki --no-pager -n 50

    exit 1
fi

################################################################################
# HTTP Health Check
################################################################################

sleep 3

if curl -fs http://localhost:3100/ready >/dev/null; then

    success "Loki is ready."

else

    error "Loki HTTP endpoint not responding."

    exit 1
fi

################################################################################
# Version
################################################################################

echo
echo "Installed Loki Version:"
${LOKI_BINARY} --version

success "Loki installation completed."
