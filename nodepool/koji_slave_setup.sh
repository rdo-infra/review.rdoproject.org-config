#!/bin/bash

. base.sh

# install ansible
sudo yum install -y epel-release
sudo yum install -y python-crypto git python-pip
sudo pip install -U ansible==1.9.2
ansible --version

# install tox and gcc/python-dev to be able to build native python
# modules
sudo yum install -y koji wget rpmdevtools rpm-build redhat-rpm-config
sudo yum install -y python-devel gcc patch libffi-devel mock rsync createrepo
sudo pip install -U tox==1.6.1

# swap
sudo dd if=/dev/zero of=/srv/swap count=4000 bs=1M
sudo chmod 600 /srv/swap
sudo mkswap /srv/swap
grep swap /etc/fstab || echo "/srv/swap none swap sw 0 0" | sudo tee -a /etc/fstab

# Koji configuration and certs (completly insecure)
sudo wget http://koji-rpmfactory.ring.enovance.com/conf/koji.conf -O /etc/koji.conf
sudo wget http://koji-rpmfactory.ring.enovance.com/conf/jenkins-koji.tgz -O /srv/jenkins-koji.tgz
sudo tar xvzf /srv/jenkins-koji.tgz -C /home/jenkins/
sudo chown -R jenkins /home/jenkins/.koji

# OpenStack projects configuration (tox+deps)
# http://docs.openstack.org/developer/requirements/
git clone http://softwarefactory-project.io/r/rpmfactory
sudo cp rpmfactory/slaves/cloud.repo /etc/yum.repos.d/
sudo cp rpmfactory/slaves/run-tox.sh /usr/local/bin/

# https://github.com/openstack-infra/system-config/blob/master/modules/openstack_project/manifests/thick_slave.pp
sudo yum install -y mariadb-devel postgresql-devel libjpeg-devel
sudo yum install -y gcc-c++ zeromq-devel libxslt-devel sqlite-devel
sudo yum install -y libvirt-devel openldap-devel libxml2-devel
sudo yum install -y liberasurecode-devel openssl-devel

# install khaleesi
git clone https://github.com/redhat-openstack/khaleesi.git
git clone https://github.com/redhat-openstack/khaleesi-settings.git

pushd khaleesi/tools/ksgen
sudo python setup.py install
popd

# sync FS, otherwise there are 0-byte sized files from the yum/pip installations
sudo sync

# Remove epel and cloud repo
sudo yum remove -y epel-release
sudo rm /etc/yum.repos.d/cloud.repo

echo "Setup finished. Creating snapshot now, this will take a few minutes"
