#!/bin/bash

########################################################################
# This script was modified by Kevin to fulfil the updated requirements #
########################################################################

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


# Install containerd
sudo apt-get update
sudo apt-get -y install containerd

# Configure containerd with defaults and restart with this config
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Verify that containerd is installed and running
echo "Verifying that containerd is installed and running, there should be an active status below:"
sudo systemctl status containerd.service --no-pager | grep Active

# Verify that the configuration was updated correctly
echo "Verifying that the configuration was updated correctly, there should be a true value below:"
sudo cat /etc/containerd/config.toml | grep SystemdCgroup
