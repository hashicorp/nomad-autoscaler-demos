#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

set -Eeuo pipefail

LOG_FILE=/var/log/provision.log
if [[ -z "${_PROVISION_LOG_INITIALIZED:-}" ]]; then
  sudo install -o "$(id -u)" -g "$(id -g)" -m 0644 /dev/null "$LOG_FILE" || true
  exec > >(tee -a "$LOG_FILE")
  exec 2>&1
  export _PROVISION_LOG_INITIALIZED=1
fi
log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

log "Starting net.sh"
trap 'log "net.sh failed (exit code $?)"' ERR

function net_getInterfaceAddress() {
  ip -4 address show "${1}" | awk '/inet / { print $2 }' | cut -d/ -f1
}

function net_getDefaultRouteAddress() {
  # Default route IP address (seems to be a good way to get host ip)
  ip -4 route get 1.1.1.1 | grep -oP 'src \K\S+'
}

log "Finished net.sh"
