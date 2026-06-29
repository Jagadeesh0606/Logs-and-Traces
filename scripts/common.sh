#!/bin/bash
################################################################################
# common.sh
#
# Common utility functions for the Amazon Linux 2023 Observability Stack
################################################################################

set -euo pipefail

################################################################################
# Colors
################################################################################

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
NC="\033[0m"

################################################################################
# Logging
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_header() {
    echo
    echo "====================================================================="
    echo -e "${CYAN}$*${NC}"
    echo "====================================================================="
}

################################################################################
# Exit Handler
################################################################################

fatal() {
    log_error "$*"
    exit 1
}

################################################################################
# Root Check
################################################################################

require_root() {
    if [[ $EUID -ne 0 ]]; then
        fatal "Please run this script with sudo or as root."
    fi
}

################################################################################
# Command Check
################################################################################

require_command() {

    local cmd="$1"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        fatal "Required command not found: ${cmd}"
    fi
}

################################################################################
# Service Helpers
################################################################################

enable_service() {
    local svc="$1"

    systemctl daemon-reload

    systemctl enable "$svc"
}

start_service() {
    local svc="$1"

    systemctl restart "$svc"
}

stop_service() {
    local svc="$1"

    systemctl stop "$svc" || true
}

restart_service() {
    local svc="$1"

    systemctl restart "$svc"
}

service_active() {

    local svc="$1"

    systemctl is-active --quiet "$svc"
}

wait_for_service() {

    local svc="$1"

    local retries=20

    local delay=3

    while (( retries > 0 ))
    do

        if service_active "$svc"; then
            return 0
        fi

        sleep "$delay"

        retries=$((retries-1))

    done

    return 1
}

################################################################################
# HTTP Health Check
################################################################################

wait_for_http() {

    local url="$1"

    local retries=30

    local delay=2

    while (( retries > 0 ))
    do

        if curl -fs "$url" >/dev/null 2>&1; then
            return 0
        fi

        sleep "$delay"

        retries=$((retries-1))

    done

    return 1
}

################################################################################
# Download Helper
################################################################################

download() {

    local url="$1"

    local output="$2"

    log_info "Downloading $(basename "$output")"

    curl -L --fail --retry 5 --retry-delay 3 \
        -o "$output" \
        "$url"
}

################################################################################
# Extract Archives
################################################################################

extract_tar_gz() {

    local archive="$1"

    local destination="$2"

    mkdir -p "$destination"

    tar -xzf "$archive" -C "$destination"
}

extract_zip() {

    local archive="$1"

    local destination="$2"

    mkdir -p "$destination"

    unzip -o "$archive" -d "$destination"
}

################################################################################
# User Helpers
################################################################################

create_system_user() {

    local user="$1"

    if ! id "$user" >/dev/null 2>&1; then

        useradd \
            --system \
            --no-create-home \
            --shell /sbin/nologin \
            "$user"

        log_info "Created system user: $user"

    fi
}

################################################################################
# Directory Helpers
################################################################################

create_dir() {

    local path="$1"

    local owner="${2:-root}"

    local group="${3:-root}"

    local perms="${4:-755}"

    mkdir -p "$path"

    chown -R "${owner}:${group}" "$path"

    chmod "$perms" "$path"
}

################################################################################
# Firewall
################################################################################

open_firewall_port() {

    local port="$1"

    if systemctl is-active --quiet firewalld; then

        firewall-cmd --permanent --add-port="${port}/tcp"

    fi
}

reload_firewall() {

    if systemctl is-active --quiet firewalld; then

        firewall-cmd --reload

    fi
}

################################################################################
# Version
################################################################################

print_version() {

    local binary="$1"

    if [[ -x "$binary" ]]; then

        "$binary" --version || true

    fi
}

################################################################################
# Internet Check
################################################################################

check_internet() {

    log_info "Checking internet connectivity..."

    if curl -Is https://github.com >/dev/null 2>&1; then

        log_success "Internet connection available."

    else

        fatal "Internet connection unavailable."

    fi
}

################################################################################
# Cleanup
################################################################################

cleanup_tmp() {

    rm -rf /tmp/observability/* 2>/dev/null || true
}

################################################################################
# Banner
################################################################################

banner() {

cat <<EOF

===============================================================
 Amazon Linux 2023 Observability Stack
===============================================================

Components

  ✔ Grafana OSS
  ✔ Loki
  ✔ Grafana Alloy
  ✔ Tempo
  ✔ OpenTelemetry Collector
  ✔ Node Exporter

===============================================================

EOF

}

################################################################################
# Verify Ports
################################################################################

check_port() {

    local port="$1"

    if ss -tln | grep -q ":${port} "; then

        log_success "Port ${port} is listening."

    else

        log_warning "Port ${port} is not listening."

    fi
}

################################################################################
# Timestamp
################################################################################

timestamp() {

    date +"%Y-%m-%d %H:%M:%S"

}
