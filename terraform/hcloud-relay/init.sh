#!/bin/bash

wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -xf go1.21.0.linux-amd64.tar.gz
sudo mv go /usr/local
echo "export GOROOT=/usr/local/go" >> $HOME/.profile
echo "export GOPATH=$HOME/go" >> $HOME/.profile
echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> $HOME/.profile
source $HOME/.profile

curl -fsSL https://tailscale.com/install.sh | sh

echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo "net.ipv6.conf.all.forwarding = 1" | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

tailscale up --authkey="${tailscale_auth_key}"
tailscale set --ssh
tailscale set --advertise-exit-node

go install tailscale.com/cmd/derper@main

sudo systemctl enable derper.service
sudo systemctl start derper.service

# reboot
