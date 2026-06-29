#!/bin/bash
################################################################################
# install_alloy.sh
#
# Installs Grafana Alloy on Amazon Linux 2023
################################################################################

set -euo pipefail

################################################################################
# Load Common Functions
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/common.sh"

require_root

log_header "Installing Grafana Alloy"

################################################################################
# Variables
################################################################################

REPO_FILE="/etc/yum.repos.d/grafana.repo"

################################################################################
# Create Alloy User
################################################################################

create_system_user alloy

################################################################################
# Create Directories
################################################################################

create_dir "/etc/alloy" alloy alloy

create_dir "/var/lib/alloy" alloy alloy

create_dir "/var/log/alloy" alloy alloy

################################################################################
# Configure Grafana Repository
################################################################################

if [[ ! -f "${REPO_FILE}" ]]; then

cat > "${REPO_FILE}" <<EOF
[grafana]
name=Grafana OSS
baseurl=https://rpm.grafana.com
enabled=1
gpgcheck=1
repo_gpgcheck=1
sslverify=1
gpgkey=https://rpm.grafana.com/gpg.key
EOF

fi

################################################################################
# Refresh Repository
################################################################################

log_info "Refreshing DNF cache..."

dnf clean all

dnf makecache

################################################################################
# Install Alloy
################################################################################

log_info "Installing Grafana Alloy..."

dnf install -y alloy

################################################################################
# Verify Installation
################################################################################

if ! command -v alloy >/dev/null 2>&1; then

    fatal "Grafana Alloy installation failed."

fi

################################################################################
# Configuration File
################################################################################

if [[ ! -f /etc/alloy/config.alloy ]]; then

cat >/etc/alloy/config.alloy <<'EOF'
// Placeholder configuration.
// This file will be replaced in alloy/config.alloy

logging {
  level = "info"
}
EOF

fi

################################################################################
# Permissions
################################################################################

chown -R alloy:alloy /etc/alloy

chown -R alloy:alloy /var/lib/alloy

################################################################################
# Enable Service
################################################################################

enable_service alloy

################################################################################
# Start Service
################################################################################

start_service alloy

################################################################################
# Wait
################################################################################

if wait_for_service alloy; then

    log_success "Grafana Alloy service started."

else

    journalctl -u alloy --no-pager -n 50

    fatal "Grafana Alloy failed to start."

fi

################################################################################
# Service Status
################################################################################

systemctl --no-pager --full status alloy || true

################################################################################
# Version
################################################################################

echo
echo "Installed Version:"
alloy --version

################################################################################
# Finished
################################################################################

log_success "Grafana Alloy installation completed."
