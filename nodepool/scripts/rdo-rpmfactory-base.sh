#!/bin/bash
# RDO "fork" of rpmfactory-base.sh

# Create swap
sudo dd if=/dev/zero of=/.swap count=4000 bs=1M
sudo chmod 0600 /.swap
sudo mkswap /.swap
grep swap /etc/fstab || echo "/.swap none swap sw 0 0" | sudo tee -a /etc/fstab



# Install minimum for RPM factory jobs
sudo yum install -y koji centos-packager wget rpmdevtools \
                    rpm-build redhat-rpm-config mock rsync \
                    createrepo

# Add jenkins to the mock group
sudo usermod -a -G mock jenkins

# Here is the default koji config file for CBS
cat /etc/koji.conf.d/cbs-koji.conf
# The following files will need to be installed when
# a job using CBS will start. Please use Jenkins Credential binding
# /home/jenkins/.centos-server-ca.cert
# /home/jenkins/.centos.cert

# sync FS, otherwise there are 0-byte sized files from the yum/pip installations
sudo sync

echo "Setup finished. Creating snapshot now, this will take a few minutes"
