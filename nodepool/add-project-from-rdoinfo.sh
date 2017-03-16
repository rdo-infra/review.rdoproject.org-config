#!/bin/bash

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

cat > resources/${PREFIX}-${PROJECT_NAME}.yaml << EOF
resources:
  groups:
    ${PREFIX}/${PROJECT_NAME}-core:
      description: Core developers for project ${PROJECT_NAME}
      members:
EOF

for MAINTAINER in ${MAINTAINER_LIST}; do
echo "      - ${MAINTAINER}" >> resources/${PREFIX}-${PROJECT_NAME}.yaml
done

cat >> resources/${PREFIX}-${PROJECT_NAME}.yaml << EOF2
    ${PREFIX}/${PROJECT_NAME}-ptl:
      description: Project team lead for project ${PROJECT_NAME}
      members:
      - sfrdobender@rpmfactory.beta.rdoproject.org
      - admin@review.rdoproject.org
  acls:
    openstack-${PROJECT_NAME}-distgit:
      file: |
        [access "refs/*"]
          read = group ${PREFIX}/${PROJECT_NAME}-core
          owner = group ${PREFIX}/${PROJECT_NAME}-ptl
          owner = rdo-superusers
        [access "refs/heads/*"]
          label-Code-Review = -2..+2 group ${PREFIX}/${PROJECT_NAME}-core
          label-Code-Review = -2..+2 group ${PREFIX}/${PROJECT_NAME}-ptl
          label-Code-Review = -2..+2 group rdo-provenpackagers
          label-Code-Review = -2..+2 group rdo-superusers
          submit = group ${PREFIX}/${PROJECT_NAME}-ptl
          submit = group rdo-superusers
          read = group Registered Users
          read = group ${PREFIX}/${PROJECT_NAME}-core
          read = group rdo-provenpackagers
          label-Verified = -2..+2 group ${PREFIX}/${PROJECT_NAME}-ptl
          label-Verified = -2..+2 group rdo-superusers
          label-Workflow = -1..+0 group Registered Users
          label-Workflow = -1..+1 group ${PREFIX}/${PROJECT_NAME}-core
          label-Workflow = -1..+1 group ${PREFIX}/${PROJECT_NAME}-ptl
          label-Workflow = -1..+1 group rdo-provenpackagers
        [access "refs/meta/config"]
          read = group Registered Users
          read = group ${PREFIX}/${PROJECT_NAME}-core
          read = group rdo-provenpackagers
        [receive]
          requireChangeId = true
        [submit]
          mergeContent = false
          action = rebase if necessary
      groups:
      - ${PREFIX}/${PROJECT_NAME}-core
      - ${PREFIX}/${PROJECT_NAME}-ptl
      - rdo-provenpackagers
      - rdo-superusers
    openstack-${PROJECT_NAME}:
      file: |
        [access "refs/*"]
          read = group ${PREFIX}/${PROJECT_NAME}-core
          owner = group ${PREFIX}/${PROJECT_NAME}-ptl
          owner = rdo-superusers
        [access "refs/heads/*"]
          label-Code-Review = -2..+2 group ${PREFIX}/${PROJECT_NAME}-core
          label-Code-Review = -2..+2 group ${PREFIX}/${PROJECT_NAME}-ptl
          label-Code-Review = -2..+2 group rdo-provenpackagers
          label-Code-Review = -2..+2 group rdo-superusers
          submit = group ${PREFIX}/${PROJECT_NAME}-ptl
          submit = group rdo-superusers
          read = group Registered Users
          read = group ${PREFIX}/${PROJECT_NAME}-core
          read = group rdo-provenpackagers
          label-Verified = -2..+0 group ${PREFIX}/${PROJECT_NAME}-ptl
          label-Verified = -2..+0 group rdo-superusers
          label-Workflow = -1..+0 group Registered Users
          label-Workflow = -1..+0 group ${PREFIX}/${PROJECT_NAME}-core
          label-Workflow = -1..+0 group ${PREFIX}/${PROJECT_NAME}-ptl
          label-Workflow = -1..+0 group rdo-provenpackagers
        [access "refs/meta/config"]
          read = group Registered Users
          read = group ${PREFIX}/${PROJECT_NAME}-core
          read = group rdo-provenpackagers
        [receive]
          requireChangeId = true
        [submit]
          mergeContent = false
          action = rebase if necessary
      groups:
      - ${PREFIX}/${PROJECT_NAME}-core
      - ${PREFIX}/${PROJECT_NAME}-ptl
      - rdo-provenpackagers
      - rdo-superusers
  repos:
    ${PREFIX}/${PROJECT_NAME}:
      acl: openstack-${PROJECT_NAME}
      description: Mirror of upstream ${PROJECT_NAME} (mirror + patches)
    ${PREFIX}/${PROJECT_NAME}-distgit:
      acl: openstack-${PROJECT_NAME}
      description: Packaging of upstream ${PROJECT_NAME}
EOF2

pushd resources
mkdir -p ~/.ssh
cat >> ~/.ssh/config << EOF

Host review.rdoproject.org
  IdentityFile $SSH_KEY
EOF

chmod 600 ~/.ssh/config
sudo chmod 600 $SSH_KEY
sudo chown jenkins:jenkins $SSH_KEY
ssh-keyscan -p 29418 review.rdoproject.org >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
git config user.name "rdo-trunk"
git config user.email "javier.pena@redhat.com"
git config gitreview.username "rdo-trunk"
git checkout -b new-project-$PROJECT_NAME
git review -s -v
COMMIT_MSG="Create project for $PROJECT_NAME"
git add *.yaml
echo -e $COMMIT_MSG | git commit -F-
git review -t "add-${PROJECT_NAME}" < /dev/null
popd
popd
