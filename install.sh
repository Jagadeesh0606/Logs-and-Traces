#!/bin/bash
################################################################################
# Amazon Linux 2023 Observability Stack Installer
#
# Components:
#   - Grafana OSS
#   - Loki
#   - Grafana Alloy
#   - Tempo
#   - OpenTelemetry Collector
#   - Node Exporter
#
# Author: Jagadeeswarareddy Byreddi
################################################################################

set -euo pipefail

################################################################################
# Variables
################################################################################

PROJECT="Amazon Linux 2023 Observability Stack"

INSTALL_DIR="/opt/observability"

DOWNLOAD_DIR="/tmp/observability"

LOG_DIR="/var/log/observability"

SERVICE_DIR="/etc/systemd/system"

CONFIG_DIR="/etc/observability"

GRAFANA_VERSION="latest"

LOKI_VERSION="latest"

TEMPO_VERSION="latest"

ALLOY_VERSION="latest"

OTEL_VERSION="0.129.1"

NODE_EXPORTER_VERSION="1.9.1"

################################################################################
# Colors
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

################################################################################
# Helper Functions
################################################################################

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

################################################################################
# Root Check
################################################################################

if [[ $EUID -ne 0 ]]; then
    error "Please run this installer as root."

    echo

    echo "Example:"

    echo "sudo ./install.sh"

    exit 1
fi

################################################################################
# Banner
################################################################################

clear

echo "=============================================================="

echo "        Amazon Linux 2023 Observability Stack"

echo

echo "Components"

echo "  • Grafana"

echo "  • Loki"

echo "  • Grafana Alloy"

echo "  • Tempo"

echo "  • OpenTelemetry Collector"

echo "  • Node Exporter"

echo

echo "=============================================================="

################################################################################
# Update System
################################################################################

info "Updating operating system..."

dnf clean all

dnf makecache

dnf update -y

################################################################################
# Install Required Packages
################################################################################

info "Installing prerequisite packages..."

dnf install -y \
curl \
wget \
git \
tar \
gzip \
unzip \
jq \
vim \
nano \
which \
shadow-utils \
systemd \
hostname \
openssl \
firewalld

success "Prerequisite packages installed."

################################################################################
# Create Directories
################################################################################

info "Creating directory structure..."

mkdir -p "${INSTALL_DIR}"

mkdir -p "${DOWNLOAD_DIR}"

mkdir -p "${LOG_DIR}"

mkdir -p "${CONFIG_DIR}"

mkdir -p /etc/loki

mkdir -p /etc/tempo

mkdir -p /etc/alloy

mkdir -p /etc/otel

mkdir -p /etc/grafana/provisioning

mkdir -p /var/lib/loki

mkdir -p /var/lib/tempo

mkdir -p /var/lib/alloy

mkdir -p /var/lib/otel

success "Directories created."

################################################################################
# Create System Users
################################################################################

info "Creating service users..."

id grafana >/dev/null 2>&1 || useradd --system --no-create-home --shell /sbin/nologin grafana

id loki >/dev/null 2>&1 || useradd --system --no-create-home --shell /sbin/nologin loki

id alloy >/dev/null 2>&1 || useradd --system --no-create-home --shell /sbin/nologin alloy

id tempo >/dev/null 2>&1 || useradd --system --no-create-home --shell /sbin/nologin tempo

id otel >/dev/null 2>&1 || useradd --system --no-create-home --shell /sbin/nologin otel

success "Users created."

################################################################################
# Set Permissions
################################################################################

info "Setting permissions..."

chown -R loki:loki /var/lib/loki

chown -R tempo:tempo /var/lib/tempo

chown -R alloy:alloy /var/lib/alloy

chown -R otel:otel /var/lib/otel

chmod -R 755 /etc/loki

chmod -R 755 /etc/tempo

chmod -R 755 /etc/alloy

chmod -R 755 /etc/otel

success "Permissions configured."

################################################################################
# Enable Firewall
################################################################################

if systemctl is-enabled firewalld >/dev/null 2>&1; then

    info "Configuring firewall..."

    firewall-cmd --permanent --add-port=3000/tcp

    firewall-cmd --permanent --add-port=3100/tcp

    firewall-cmd --permanent --add-port=3200/tcp

    firewall-cmd --permanent --add-port=4317/tcp

    firewall-cmd --permanent --add-port=4318/tcp

    firewall-cmd --permanent --add-port=9100/tcp

    firewall-cmd --reload

fi

################################################################################
# Verify Internet Connectivity
################################################################################

info "Checking Internet connectivity..."

if ! curl -Is https://github.com >/dev/null; then
    error "Unable to reach GitHub."

    exit 1
fi

success "Internet connection verified."

################################################################################
# Begin Installation
################################################################################

echo

echo "=============================================================="

echo "Starting Component Installation..."

echo "=============================================================="

################################################################################
# Install Components
################################################################################

bash scripts/install_grafana.sh

bash scripts/install_loki.sh

bash scripts/install_alloy.sh

bash scripts/install_tempo.sh

bash scripts/install_otel.sh

bash scripts/install_node_exporter.sh

################################################################################
# Provision Grafana
################################################################################

info "Provisioning Grafana..."

cp -r grafana/provisioning/* /etc/grafana/provisioning/

################################################################################
# Reload systemd
################################################################################

systemctl daemon-reload

################################################################################
# Enable Services
################################################################################

systemctl enable grafana-server

systemctl enable loki

systemctl enable alloy

systemctl enable tempo

systemctl enable otelcol

systemctl enable node_exporter

################################################################################
# Start Services
################################################################################

systemctl restart grafana-server

systemctl restart loki

systemctl restart alloy

systemctl restart tempo

systemctl restart otelcol

systemctl restart node_exporter

################################################################################
# Verify Installation
################################################################################

bash verify.sh

################################################################################
# Finish
################################################################################

echo

echo "=============================================================="

success "Installation Complete."

echo

echo "Grafana : http://$(hostname -I | awk '{print $1}'):3000"

echo "Loki    : http://$(hostname -I | awk '{print $1}'):3100"

echo "Tempo   : http://$(hostname -I | awk '{print $1}'):3200"

echo

echo "Username : admin"

echo "Password : admin"

echo

echo "=============================================================="
