#!/bin/bash
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

sudo systemctl start nomad.service
sleep 10
export NOMAD_ADDR=http://$IP_ADDRESS:4646

# Add hostname to /etc/hosts
echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts

# dnsmasq config
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

# Set /opt permissions
sudo find /opt -type d -exec chmod g+s {} \\;
sudo chown -R root:ubuntu /opt
sudo chmod -R g+rX /opt

# Set env vars for tool CLIs
echo "export CONSUL_RPC_ADDR=$IP_ADDRESS:8400" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export CONSUL_HTTP_ADDR=$IP_ADDRESS:8500" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export NOMAD_ADDR=http://$IP_ADDRESS:4646" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre"  | sudo tee --append /home/$HOME_DIR/.bashrc
echo "alias env='env -0 | tr "\0" "\n" | sort'" | sudo tee --append /home/$HOME_DIR/.bashrc

# set terminal color
echo "export TERM=xterm-256color" | sudo tee --append /home/$HOME_DIR/.bashrc
# set terminal prompt
local marker="# >>> custom WarpTerminal PS1 block >>>"
if ! grep -Fq "$marker" ~/.bashrc; then
  cat <<'EOF' >> ~/.bashrc
# >>> custom WarpTerminal PS1 block >>>
if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then
  PS1="\[\033[0;33m\](\$PROMPTID)[Int: \$PRIIP / Ext: \$PUBIP] \[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
else
  PS1="\[\033[0;33m\](\$PROMPTID)[Int: \$PRIIP / Ext: \$PUBIP]\[\033[0m\]\n\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
fi
# <<< custom WarpTerminal PS1 block <<<
EOF
  echo "[INFO] Appended PS1 block to .bashrc."
else
  echo "[INFO] PS1 block already in .bashrc."
fi