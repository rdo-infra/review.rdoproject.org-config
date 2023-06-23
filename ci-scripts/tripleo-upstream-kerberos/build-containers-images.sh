set -e

echo ======== BUILD CONTAINERS IMAGES

# Retrieve role
mkdir -p $WORKSPACE/roles
pushd $WORKSPACE/roles
    git clone https://github.com/rdo-infra/ansible-role-rdo-kolla-build rdo-kolla-build
popd

# Delete any leftover configuration ansible
rm -f $WORKSPACE/ansible.cfg
TESTING_TAG="tripleo-ci-testing"
# devstack gate sets this, but conflicts with anything else
unset ANSIBLE_STDOUT_CALLBACK
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_ROLES_PATH="$WORKSPACE/roles"

# Retain the lack of arch in namespace for x86_64 containers
if [ "$CPU_ARCH" = "x86_64" ] || [ "$CPU_ARCH" = "" ]; then
    CPU_ARCH=""
else
    CPU_ARCH="-$CPU_ARCH"
fi

DISTRO="${DISTRO_NAME}${DISTRO_VERSION}"

if [ "$DISTRO_NAME" = "fedora" ]; then
    PUSH="false"
fi

cat << EOF > $WORKSPACE/playbook.yml
---
- name: Build Kolla images
  hosts: localhost
  become: yes
  become_user: root
  vars:
    kolla_base: "${DISTRO_NAME}"
    kolla_base_image: "${DISTRO_NAME}"
    kolla_base_tag: "${DISTRO_VERSION}"
    kolla_virtualenv: "{{ kolla_tmpdir }}/.tox/build-${DISTRO_NAME}-binary"
    kolla_namespace: "tripleo${RELEASE}${CPU_ARCH}"
    kolla_push: "${PUSH:-true}"
    kolla_tag: "$TESTING_TAG"
    openstack_release: "$RELEASE"
    kolla_registry: "${CONTAINER_REGISTRY:-trunk.registry.rdoproject.org}"
    trunk_repository: "https://trunk.rdoproject.org/${DISTRO}-$RELEASE/$TESTING_TAG/delorean.repo"
    trunk_deps_repository: "https://trunk.rdoproject.org/${DISTRO}-$RELEASE/delorean-deps.repo"
  tasks:
    - include_role:
        name: "rdo-kolla-build"
EOF

ansible-playbook $WORKSPACE/playbook.yml -e kolla_threads=16

echo ======== BUILD CONTAINERS IMAGES COMPLETED
