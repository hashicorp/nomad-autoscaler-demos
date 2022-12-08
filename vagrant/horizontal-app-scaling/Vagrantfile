# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  # Expose ports to the host.
  config.vm.network "forwarded_port", guest: 3000, host: 3000, host_ip: "127.0.0.1"    # Grafana
  config.vm.network "forwarded_port", guest: 4646, host: 4646, host_ip: "127.0.0.1"    # Nomad
  config.vm.network "forwarded_port", guest: 8000, host: 8000, host_ip: "127.0.0.1"    # Demo webapp
  config.vm.network "forwarded_port", guest: 8081, host: 8081, host_ip: "127.0.0.1"    # Traefik admin
  config.vm.network "forwarded_port", guest: 9090, host: 9090, host_ip: "127.0.0.1"    # Prometheus

  # Share current directory with jobs and configuration files with the VM. Add
  # the shared files in a sub-dir.
  config.vm.synced_folder "./", "/home/vagrant/nomad-autoscaler"
  config.vm.synced_folder "../shared", "/home/vagrant/nomad-autoscaler-shared"

  # VM configuration.
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
  end

  # Provision demo dependencies.
  #   - Downloads and install Nomad and Docker
  # Only runs when the VM is created.
  config.vm.provision "deps", type: "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive

    # Install dependencies.
    apt-get update
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      jq \
      software-properties-common \
      hey \
      zip

    # Download and install Docker.
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
    echo "deb [signed-by=/usr/share/keyrings/docker.gpg arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io
    docker run hello-world
    usermod -aG docker vagrant

    # Download and install Nomad.
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
    apt-get update
    apt-get install -y \
      nomad
  SHELL

  # Setup demo dependencies.
  #   - Create daemon for Nomad
  # Runs everytime the VM starts.
  config.vm.provision "app:setup", type: "shell", run: "always", inline: <<-SHELL
    # Create paths for Nomad host volumes.
    mkdir -p /opt/nomad-volumes
    pushd /opt/nomad-volumes
    mkdir -p grafana
    chown 472:472 grafana
    popd

    # Copy across the config files.
    cp /home/vagrant/nomad-autoscaler/files/nomad.hcl /etc/nomad.d/

    # Enable and start the daemons
    sudo systemctl enable nomad
    sudo systemctl start nomad
  SHELL

end
