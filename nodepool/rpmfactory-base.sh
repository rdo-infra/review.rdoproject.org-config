#!/bin/bash

# /!\ This is the base preparation script of RPMFactory
# to interact with a koji server. Please do not modify it /!\

# You can include it in another preparation script if you need
# to add more components to your slave

. base.sh

# Install minimum for RPM factory jobs
sudo yum install -y koji centos-packager wget rpmdevtools \
                    rpm-build redhat-rpm-config mock rsync \
                    createrepo

# Add jenkins to the mock group
sudo usermod -a -G mock jenkins

# Setup /etc/koji.conf
# This will be the default configuration when the slave
# uses the koji command.
kojiconf="
; koji rpmfactory config
[koji]

;configuration for koji cli tool

;url of XMLRPC server
server = http://koji-rpmfactory.ring.enovance.com/kojihub

;url of web interface
weburl = http://koji-rpmfactory.ring.enovance.com/koji

;url of package download site
topurl = http://koji-rpmfactory.ring.enovance.com/kojifiles

;path to the koji top directory
topdir = /mnt/koji

;configuration for SSL authentication

;client certificate
cert = ~/.koji/client.crt

;certificate of the CA that issued the client certificate
ca = ~/.koji/clientca.crt

;certificate of the CA that issued the HTTP server certificate
serverca = ~/.koji/serverca.crt
"
echo "$kojiconf" | sudo tee /etc/koji.conf

# Prepare jenkins user storage for koji client credentials
# The following files will need to be installed when
# a job using CBS will start. Please use Jenkins Credential binding
sudo mkdir /home/jenkins/.koji
sudo chown -R jenkins /home/jenkins/.koji

# Here is the default koji config file for CBS
cat /etc/koji.conf.d/cbs-koji.conf
# The following files will need to be installed when
# a job using CBS will start. Please use Jenkins Credential binding
# /home/jenkins/.centos-server-ca.cert
# /home/jenkins/.centos.cert

# sync FS, otherwise there are 0-byte sized files from the yum/pip installations
sudo sync

echo "Setup finished. Creating snapshot now, this will take a few minutes"
