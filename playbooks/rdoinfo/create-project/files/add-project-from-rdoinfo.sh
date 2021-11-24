#!/bin/bash
set -x
# Find the project name and rdoinfo location
PKG=$1
RDOINFO_LOCATION=$2
PROJECT_NAME=$(rdopkg findpkg $PKG -l ${RDOINFO_LOCATION} | grep ^project: | awk '{print $2}')
MAINTAINER_LIST=$(rdopkg findpkg $PKG -l ${RDOINFO_LOCATION} |grep -A100 maintainers: | grep -v maintainers: | awk '{print $2}')

if [[ "${PKG}" =~ puppet- ]]; then
  PREFIX="puppet"  # Puppet project
else
  PREFIX="openstack"  # Any other project goes here
fi

git clone https://review.rdoproject.org/r/config /tmp/config
pushd /tmp/config
git checkout master
git reset --hard origin/master

python ~/add-project-from-rdoinfo.py $PREFIX $PROJECT_NAME "$MAINTAINER_LIST"

python ~/add-project-on-sf.py $PREFIX $PROJECT_NAME

cat >> ~/.ssh/config << EOF

Host review.rdoproject.org
  IdentityFile ~/.ssh/rdoinfo_id_rsa
EOF

ssh-keyscan -p 29418 review.rdoproject.org >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
chmod 600 ~/.ssh/config
git config user.name "rdo-trunk"
git config user.email "amoralej+rdo-trunk@redhat.com"
git config gitreview.username "rdo-trunk"
git checkout -b new-project-$PROJECT_NAME
git review -s -v
COMMIT_MSG="Create project for $PROJECT_NAME\n\nThis is an automatically created commit, make sure you check the Zuul\nconfiguration to see if it matches the project needs.\n\nNote that a an additional review is required on [1].\n\n[1] - http://review.rdoproject.org/r/gitweb?p=config.git;a=blob;f=zuul/rdo.yaml"
git add resources/*.yaml
git add gerritbot/*.yaml
echo -e $COMMIT_MSG | git commit -F-

COMMIT_MSG="Create project info for $PROJECT_NAME in RDO\n\nThis is an automatically created commit, make sure you check the Zuul\nconfiguration to see if it matches the project needs.\n\n"
git add zuul/*.yaml
echo -e $COMMIT_MSG | git commit -F-

git add zuul.d/*.yaml
COMMIT_MSG="Add Zuul definitions for $PROJECT_NAME\n\nNote that this review will fail to pass CI until the corresponding entries \nhave been created in the zuul/rdo.yaml."
echo -e $COMMIT_MSG | git commit -F-
git review -y -t "add-${PROJECT_NAME}" < /dev/null
popd
