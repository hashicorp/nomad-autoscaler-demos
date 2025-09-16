#!/bin/bash
set -Eeuo pipefail

LOG_FILE=/var/log/provision.log
if [[ -z "${_PROVISION_LOG_INITIALIZED:-}" ]]; then
  sudo install -o "$(id -u)" -g "$(id -g)" -m 0644 /dev/null "$LOG_FILE" || true
  exec > >(tee -a "$LOG_FILE")
  exec 2>&1
  export _PROVISION_LOG_INITIALIZED=1
fi
log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

log "Starting server.sh"
trap 'log "server.sh failed (exit code $?)"' ERR
trap 'log "Finished server.sh"' EXIT

echo -e "\nInstalling SERVER...\n"

# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

SHAREDDIR=/ops/
CONFIGDIR=$SHAREDDIR/config
SCRIPTDIR=$SHAREDDIR/scripts

source $SCRIPTDIR/net.sh
set -e

CONSULCONFIGDIR=/etc/consul.d
NOMADCONFIGDIR=/etc/nomad.d
HOME_DIR=ubuntu

# Wait for network
sleep 15

IP_ADDRESS=$(net_getDefaultRouteAddress)
DOCKER_BRIDGE_IP_ADDRESS=$(net_getInterfaceAddress docker0)
CLOUD=$1
SERVER_COUNT=$2
RETRY_JOIN=$3

# Consul
## Replace existing Consul binary if remote file exists
if [[ `wget -S --spider $CONSUL_BINARY  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  curl -L $CONSUL_BINARY > consul.zip
  sudo unzip -o consul.zip -d /usr/local/bin
  sudo chmod 0755 /usr/local/bin/consul
  sudo chown root:root /usr/local/bin/consul
fi

sed -i "s/IP_ADDRESS/$IP_ADDRESS/g" $CONFIGDIR/consul.hcl
sed -i "s/SERVER_COUNT/$SERVER_COUNT/g" $CONFIGDIR/consul.hcl
sed -i "s/RETRY_JOIN/$RETRY_JOIN/g" $CONFIGDIR/consul.hcl
sudo cp $CONFIGDIR/consul.hcl $CONSULCONFIGDIR
sudo cp $CONFIGDIR/consul_$CLOUD.service /etc/systemd/system/consul.service

sudo systemctl enable consul
sudo systemctl start consul.service
sleep 10
export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500
export CONSUL_RPC_ADDR=$IP_ADDRESS:8400

# Nomad

## Replace existing Nomad binary if remote file exists
if [[ `wget -S --spider $NOMAD_BINARY  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  curl -L $NOMAD_BINARY > nomad.zip
  sudo unzip -o nomad.zip -d /usr/local/bin
  sudo chmod 0755 /usr/local/bin/nomad
  sudo chown root:root /usr/local/bin/nomad
fi

sed -i "s/SERVER_COUNT/$SERVER_COUNT/g" $CONFIGDIR/nomad.hcl
sudo cp $CONFIGDIR/nomad.hcl $NOMADCONFIGDIR
sudo cp $CONFIGDIR/nomad.service /etc/systemd/system/nomad.service

sudo systemctl enable nomad
sudo systemctl start nomad.service
sleep 10
export NOMAD_ADDR=http://$IP_ADDRESS:4646

# Add hostname to /etc/hosts
echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts

# dnsmasq config
echo -e "\nConfiguring DNSMASQ...\n"
echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf
sudo cp /ops/config/10-consul.dnsmasq /etc/dnsmasq.d/10-consul
sudo cp /ops/config/99-default.dnsmasq.$CLOUD /etc/dnsmasq.d/99-default
sudo mv /etc/resolv.conf /etc/resolv.conf.orig
grep -v "nameserver" /etc/resolv.conf.orig | grep -v -e"^#" | grep -v -e '^$' | sudo tee /etc/resolv.conf
echo "nameserver 127.0.0.1" | sudo tee -a /etc/resolv.conf
sudo systemctl restart systemd-resolved
sudo systemctl restart dnsmasq

# Add Docker bridge network IP to /etc/resolv.conf (at the top)
echo "nameserver $DOCKER_BRIDGE_IP_ADDRESS" | sudo tee /etc/resolv.conf.new
cat /etc/resolv.conf | sudo tee --append /etc/resolv.conf.new
sudo mv /etc/resolv.conf.new /etc/resolv.conf

# Set env vars for tool CLIs
echo "export CONSUL_RPC_ADDR=$IP_ADDRESS:8400" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export NOMAD_ADDR=http://$IP_ADDRESS:4646" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre"  | sudo tee --append /home/$HOME_DIR/.bashrc

# set alias
alias env="env -0 | sort -z | tr '\0' '\n'"

# set terminal color
echo "export TERM=xterm-256color" | sudo tee --append /home/$HOME_DIR/.bashrc

source $SCRIPTDIR/set-prompt.sh

log "Finished server.sh"