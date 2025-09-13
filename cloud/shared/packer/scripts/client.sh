#!/bin/bash
echo -e "\nInstalling CLIENT...\n"

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
RETRY_JOIN=$2
NODE_CLASS=$3

# Consul
sed -i "s/IP_ADDRESS/$IP_ADDRESS/g" $CONFIGDIR/consul_client.hcl
sed -i "s/RETRY_JOIN/$RETRY_JOIN/g" $CONFIGDIR/consul_client.hcl
sudo cp $CONFIGDIR/consul_client.hcl $CONSULCONFIGDIR/consul.hcl
sudo cp $CONFIGDIR/consul_$CLOUD.service /etc/systemd/system/consul.service

## Replace existing Consul binary if remote file exists
if [[ `wget -S --spider $CONSUL_BINARY  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  curl -L $CONSUL_BINARY > consul.zip
  sudo unzip -o consul.zip -d /usr/local/bin
  sudo chmod 0755 /usr/local/bin/consul
  sudo chown root:root /usr/local/bin/consul
fi

sudo systemctl enable consul
sudo systemctl start consul.service
sleep 10

# Nomad

## Replace existing Nomad binary if remote file exists
if [[ `wget -S --spider $NOMAD_BINARY  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
  curl -L $NOMAD_BINARY > nomad.zip
  sudo unzip -o nomad.zip -d /usr/local/bin
  sudo chmod 0755 /usr/local/bin/nomad
  sudo chown root:root /usr/local/bin/nomad
fi

sed -i "s/NODE_CLASS/\"$NODE_CLASS\"/g" $CONFIGDIR/nomad_client.hcl
sudo cp $CONFIGDIR/nomad_client.hcl $NOMADCONFIGDIR/nomad.hcl
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
echo "export VAULT_ADDR=http://$IP_ADDRESS:8200" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export NOMAD_ADDR=http://$IP_ADDRESS:4646" | sudo tee --append /home/$HOME_DIR/.bashrc
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre"  | sudo tee --append /home/$HOME_DIR/.bashrc


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