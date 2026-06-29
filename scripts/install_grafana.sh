#!/bin/bash
################################################################################
# install_grafana.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

require_root

# Installs Grafana OSS on Amazon Linux 2023
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

GRAFANA_REPO="/etc/yum.repos.d/grafana.repo"

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
# Verify Root
################################################################################

if [[ $EUID -ne 0 ]]; then
    error "Run this script as root."

    exit 1
fi

################################################################################
# Install Repository
################################################################################

info "Configuring Grafana Repository..."

cat > "${GRAFANA_REPO}" <<EOF
[grafana]
name=Grafana OSS Repository
baseurl=https://rpm.grafana.com
enabled=1
gpgcheck=1
repo_gpgcheck=1
sslverify=1
gpgkey=https://rpm.grafana.com/gpg.key
EOF

################################################################################
# Refresh Repository Cache
################################################################################

info "Refreshing package cache..."

dnf clean all

dnf makecache

################################################################################
# Install Grafana
################################################################################

log_info "Installing Grafana..."

dnf install -y grafana

################################################################################
# Create Provisioning Directories
################################################################################

info "Creating provisioning directories..."

mkdir -p /etc/grafana/provisioning/datasources

mkdir -p /etc/grafana/provisioning/dashboards

mkdir -p /var/lib/grafana/dashboards

################################################################################
# Set Permissions
################################################################################

chown -R grafana:grafana /var/lib/grafana

################################################################################
# Enable Service
################################################################################

info "Enabling Grafana..."

systemctl daemon-reload

systemctl enable grafana-server

################################################################################
# Start Service
################################################################################

info "Starting Grafana..."

systemctl restart grafana-server

sleep 5

################################################################################
# Health Check
################################################################################

info "Checking Grafana health..."

if systemctl is-active --quiet grafana-server; then

    success "Grafana service is running."

else

    error "Grafana service failed."

    journalctl -u grafana-server --no-pager -n 50

    exit 1

fi

################################################################################
# HTTP Health Check
################################################################################

sleep 5

if curl -s http://localhost:3000/api/health >/dev/null; then

    success "Grafana API is responding."

else

    error "Grafana API is not reachable."

fi

################################################################################
# Installed Version
################################################################################

VERSION=$(grafana-server -v | head -1)

echo

echo "----------------------------------------"

echo "Installed Version"

echo "$VERSION"

echo "----------------------------------------"

success "Grafana installation completed."

echo
