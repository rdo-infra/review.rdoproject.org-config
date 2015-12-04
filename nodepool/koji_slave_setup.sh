#!/bin/bash

. base.sh

# install ansible
sudo yum install -y epel-release
sudo yum install -y python-crypto git python-pip
sudo pip install -U ansible==1.9.2
ansible --version
sudo yum remove -y epel-release

# install tox and gcc/python-dev to be able to build native python
# modules
sudo yum install -y koji wget rpmdevtools rpm-build redhat-rpm-config
sudo yum install -y python-devel gcc patch libffi-devel
sudo pip install -U tox==1.6.1

# swap
sudo dd if=/dev/zero of=/srv/swap count=4000 bs=1M
sudo chmod 600 /srv/swap
sudo mkswap /srv/swap
grep swap /etc/fstab || echo "/srv/swap none swap sw 0 0" | sudo tee -a /etc/fstab

# Koji configuration and certs (insecure)
sudo wget http://192.168.42.27/conf/koji.conf -O /etc/koji.conf
sudo wget http://192.168.42.27/conf/jenkins-koji.tgz -O /srv/jenkins-koji.tgz
sudo tar xvzf /srv/jenkins-koji.tgz -C /home/jenkins/
sudo chown -R jenkins /home/jenkins/.koji

# install khaleesi
git clone https://github.com/redhat-openstack/khaleesi.git
git clone https://github.com/redhat-openstack/khaleesi-settings.git

pushd khaleesi/tools/ksgen
sudo python setup.py install
popd

# sync FS, otherwise there are 0-byte sized files from the yum/pip installations
sudo sync

echo "Setup finished. Creating snapshot now, this will take a few minutes"
