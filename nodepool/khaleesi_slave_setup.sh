#!/bin/bash

. base.sh

# install ansible

sudo yum install -y epel-release
sudo yum install -y python-pip python-crypto git
sudo pip install -U ansible==1.9.2
ansible --version
sudo yum remove -y epel-release

git clone https://github.com/redhat-openstack/khaleesi.git
git clone https://github.com/redhat-openstack/khaleesi-settings.git

# sync FS, otherwise there are 0-byte sized files from the yum/pip installations
sudo sync

echo "Khaleesi Slave Setup finished. Creating snapshot now, this will take a few minutes"
