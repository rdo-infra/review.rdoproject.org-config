#!/bin/bash

. base.sh

# This should be removed after we fix functestlib.sh and how
# we manage to store artifacts
sudo useradd www-data

sudo yum install -y fedora-packager wget python-pip
sudo pip install -U tox==1.6.1 python-swiftclient

sudo dd if=/dev/zero of=/srv/swap count=4000 bs=1M
sudo chmod 600 /srv/swap
sudo mkswap /srv/swap
grep swap /etc/fstab || echo "/srv/swap none swap sw 0 0" | sudo tee -a /etc/fstab

sudo sed -i 's/^.*SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config

sudo mkdir -p /var/lib/sf
sudo mkdir -p /var/lib/sf/artifacts/logs
sudo chown -R jenkins:jenkins /var/lib/sf/

# Koji configuration and certs (insecure)
sudo wget http://192.168.42.27/conf/koji.conf -O /etc/koji.conf
sudo wget http://192.168.42.27/conf/jenkins-koji.tgz -O /srv/jenkins-koji.tgz
sudo tar xvzf /srv/jenkins-koji.tgz -C /home/jenkins/
sudo chown -R jenkins /home/jenkins/.koji

# Test koji communication
sudo -u jenkins 'koji' 'moshimoshi'

# sync FS, otherwise there are 0-byte sized files from the yum/pip installations
sudo sync

echo "Setup finished. Creating snapshot now, this will take a few minutes"
