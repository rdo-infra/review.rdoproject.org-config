#!/usr/bin/env python
# Ensures that every Gerrit project is configured in Gerrit replication,
# Zuul layout and Gerritbot.

from __future__ import print_function

import collections
import glob
import json
import re
import requests
import sys
import yaml
from six.moves import configparser, StringIO

GERRIT = "https://review.rdoproject.org/r/"
PROJECT_LIST = GERRIT + "/projects/"
# Note (dmsimard): centos-opstools might be sent to #centos-devel,
#                  need to verify with them first.
IGNORED_PROJECTS = {
    'replication': [
        'All-Users',
        'gating_scripts',
        'openstack/whitebox-tempest-plugin',
        'rdo',
        'rdo_gating_scripts',
        'testbranching',
        'testproject'
    ],
    'zuul': [
        'All-Users',
        'config',
        'gating_scripts',
        'rdo',
        'rdo_gating_scripts',
        'centos-opstools/opstools-ansible',
        'rdo-infra/ansible-role-logserver',
        'rdo-infra/ansible-role-rdo-base',
        'rdo-infra/ansible-role-rdo-bot',
        'rdo-infra/ansible-role-rdo-kolla-build',
        'rdo-infra/ansible-role-rdo_dashboards',
        'rdo-infra/ansible-role-rdomonitoring',
        'rdo-infra/ansible-role-weirdo-common',
        'rdo-infra/ansible-role-weirdo-kolla',
        'rdo-infra/ansible-role-weirdo-logs',
        'rdo-infra/ansible-role-weirdo-packstack',
        'rdo-infra/ansible-role-weirdo-puppet-openstack',
        'rdo-infra/rdo-infra-playbooks',
        'rdo-infra/weirdo',
        'rdo-jobs',
        'testbranching',
        'testproject',
        'centos-opstools/kibana',
        'rdo-infra/centos-release-openstack',
        'rdo-infra/example-distgit',
        'rdo-infra/rdo-dashboards',
        'rdo-infra/rdo-release',
        'rdo-infra/rdobot',
        'rdo-infra/test-day-tools',
        'rdo-infra/puppet-dlrn',
        'rdo-infra/rdo-container-registry',
        'rdo-infra/releng',
        'openstack/ansible-pacemaker',
        'openstack/ansible-role-container-registry',
        'openstack/ansible-role-redhat-subscription',
        'openstack/ansible-role-tripleo-modify-image',
        'openstack/aodh',
        'openstack/aodhclient',
        'openstack/app-catalog-ui',
        'openstack/automaton',
        'openstack/barbican',
        'openstack/barbicanclient',
        'openstack/barbican-tempest-plugin',
        'openstack/castellan',
        'openstack/ceilometer',
        'openstack/ceilometerclient',
        'openstack/ceilometermiddleware',
        'openstack/cinder',
        'openstack/cinderclient',
        'openstack/cinder-tempest-plugin',
        'openstack/cisco-ironic-contrib',
        'openstack/cliff',
        'openstack/cloudkitty',
        'openstack/cloudkittyclient',
        'openstack/cloudkitty-dashboard',
        'openstack/collectd-ceilometer-plugin',
        'openstack/collectd-gnocchi',
        'openstack/congress',
        'openstack/congressclient',
        'openstack/congress-tempest-plugin',
        'openstack/cursive',
        'openstack/debtcollector',
        'openstack/designate',
        'openstack/designateclient',
        'openstack/designate-dashboard',
        'openstack/designate-tempest-plugin',
        'openstack/django_openstack_auth',
        'openstack/dracclient',
        'openstack/ec2-api',
        'openstack/ec2api-tempest-plugin',
        'openstack/futurist',
        'openstack/glanceclient',
        'openstack/glance_store',
        'openstack/glare',
        'openstack/glareclient',
        'openstack/gnocchi',
        'openstack/gnocchiclient',
        'openstack/hacking',
        'openstack/hardware',
        'openstack/heat-agents',
        'openstack/heatclient',
        'openstack/heat-dashboard',
        'openstack/heat-tempest-plugin',
        'openstack/heat-templates',
        'openstack/heat-translator',
        'openstack/horizon',
        'openstack/ironicclient',
        'openstack/ironic-inspector-client',
        'openstack/ironic-lib',
        'openstack/ironic-staging-drivers',
        'openstack/ironic-tempest-plugin',
        'openstack/ironic-ui',
        'openstack/k8sclient',
        'openstack/karbor',
        'openstack/karborclient',
        'openstack/karbor-dashboard',
        'openstack/keystone',
        'openstack/keystoneauth1',
        'openstack/keystoneclient',
        'openstack/keystonemiddleware',
        'openstack/keystone-tempest-plugin',
        'openstack/kolla',
        'openstack/kuryr',
        'openstack/kuryr-kubernetes',
        'openstack/kuryr-tempest-plugin',
        'openstack/magnum',
        'openstack/magnumclient',
        'openstack/magnum-tempest-plugin',
        'openstack/magnum-ui',
        'openstack/manila',
        'openstack/manilaclient',
        'openstack/manila-tempest-plugin',
        'openstack/manila-ui',
        'openstack/metalsmith',
        'openstack/microversion-parse',
        'openstack/mistralclient',
        'openstack/mistral-dashboard',
        'openstack/mistral-extra',
        'openstack/mistral-lib',
        'openstack/mistral-tempest-plugin',
        'openstack/monascaclient',
        'openstack/mox3',
        'openstack/murano',
        'openstack/murano-agent',
        'openstack/muranoclient',
        'openstack/murano-dashboard',
        'openstack/murano-tempest-plugin',
        'openstack/networking-ansible',
        'openstack/networking-arista',
        'openstack/networking-bagpipe',
        'openstack/networking-baremetal',
        'openstack/networking-bgpvpn',
        'openstack/networking-bigswitch',
        'openstack/networking-cisco',
        'openstack/networking-fujitsu',
        'openstack/networking-generic-switch',
        'openstack/networking-l2gw',
        'openstack/networking-l2gw-tempest-plugin',
        'openstack/networking-mlnx',
        'openstack/networking-odl',
        'openstack/networking-ovn',
        'openstack/networking-sfc',
        'openstack/networking-vsphere',
        'openstack/neutronclient',
        'openstack/neutron-dynamic-routing',
        'openstack/neutron-fwaas',
        'openstack/neutron-lbaas',
        'openstack/neutron-lbaas-dashboard',
        'openstack/neutron-lib',
        'openstack/neutron-tempest-plugin',
        'openstack/neutron-vpnaas',
        'openstack/novaclient',
        'openstack/novajoin',
        'openstack/novajoin-tempest-plugin',
        'openstack/octavia',
        'openstack/octaviaclient',
        'openstack/octavia-dashboard',
        'openstack/octavia-tempest-plugin',
        'openstack/openstackclient',
        'openstack/openstack-macros',
        'openstack/openstack-puppet-modules',
        'openstack/openstacksdk',
        'openstack/openstack-selinux',
        'openstack/os-brick',
        'openstack/osc-lib',
        'openstack/os-client-config',
        'openstack/os-cloud-config',
        'openstack/os-faults',
        'openstack/oslo-cache',
        'openstack/oslo-concurrency',
        'openstack/oslo-config',
        'openstack/oslo-context',
        'openstack/oslo-db',
        'openstack/oslo-i18n',
        'openstack/oslo-log',
        'openstack/oslo-messaging',
        'openstack/oslo-middleware',
        'openstack/oslo-policy',
        'openstack/oslo-privsep',
        'openstack/oslo-reports',
        'openstack/oslo-rootwrap',
        'openstack/oslo-serialization',
        'openstack/oslo-service',
        'openstack/oslo-sphinx',
        'openstack/oslotest',
        'openstack/oslo-utils',
        'openstack/oslo-versionedobjects',
        'openstack/oslo-vmware',
        'openstack/osops-tools-monitoring-oschecks',
        'openstack/osprofiler',
        'openstack/os-service-types',
        'openstack/os-testr',
        'openstack/os-traits',
        'openstack/os-vif',
        'openstack/os-win',
        'openstack/oswin-tempest-plugin',
        'openstack/os-xenapi',
        'openstack/ovsdbapp',
        'openstack/packstack',
        'openstack/panko',
        'openstack/pankoclient',
        'openstack/patrole',
        'openstack/proliantutils',
        'openstack/pycadf',
        'openstack/rally',
        'openstack/reno',
        'openstack/requestsexceptions',
        'openstack/rsdclient',
        'openstack/rsd-lib',
        'openstack/sahara',
        'openstack/saharaclient',
        'openstack/sahara-dashboard',
        'openstack/sahara-image-elements',
        'openstack/sahara-tests',
        'openstack/scciclient',
        'openstack/senlin',
        'openstack/senlinclient',
        'openstack/shade',
        'openstack/shaker',
        'openstack/stevedore',
        'openstack/sushy',
        'openstack/swift',
        'openstack/swift3',
        'openstack/swiftclient',
        'openstack/tacker',
        'openstack/tackerclient',
        'openstack/tap-as-a-service',
        'openstack/taskflow',
        'openstack/telemetry-tempest-plugin',
        'openstack/tempestconf',
        'openstack/tempest-horizon',
        'openstack/tempest-lib',
        'openstack/tooz',
        'openstack/tripleoclient',
        'openstack/tripleo-common-tempest-plugin',
        'openstack/tripleo-incubator',
        'openstack/tripleo-repos',
        'openstack/tripleo-ui',
        'openstack/tripleo-validations',
        'openstack/trove',
        'openstack/troveclient',
        'openstack/trove-dashboard',
        'openstack/trove-tempest-plugin',
        'openstack/UcsSdk',
        'openstack/virtualbmc',
        'openstack/vitrage',
        'openstack/vitrageclient',
        'openstack/vitrage-dashboard',
        'openstack/vitrage-tempest-plugin',
        'openstack/vmware-nsx',
        'openstack/vmware-nsxlib',
        'openstack/vmware-nsx-tempest-plugin',
        'openstack/watcher',
        'openstack/watcher-tempest-plugin',
        'openstack/wsme',
        'openstack/zaqar',
        'openstack/zaqarclient',
        'openstack/zaqar-tempest-plugin',
        'puppet/puppet-aodh',
        'puppet/puppet-apache',
        'puppet/puppet-archive',
        'puppet/puppet-auditd',
        'puppet/puppet-barbican',
        'puppet/puppet-cassandra',
        'puppet/puppet-ceilometer',
        'puppet/puppet-ceph',
        'puppet/puppet-certmonger',
        'puppet/puppet-cinder',
        'puppet/puppet-collectd',
        'puppet/puppet-concat',
        'puppet/puppet-congress',
        'puppet/puppet-contrail',
        'puppet/puppet-corosync',
        'puppet/puppet-datacat',
        'puppet/puppet-designate',
        'puppet/puppet-dns',
        'puppet/puppet-ec2api',
        'puppet/puppet-elasticsearch',
        'puppet/puppet-etcd',
        'puppet/puppet-fdio',
        'puppet/puppet-firewall',
        'puppet/puppet-fluentd',
        'puppet/puppet-git',
        'puppet/puppet-glance',
        'puppet/puppet-gnocchi',
        'puppet/puppet-haproxy',
        'puppet/puppet-heat',
        'puppet/puppet-horizon',
        'puppet/puppet-inifile',
        'puppet/puppet-ipaclient',
        'puppet/puppet-ironic',
        'puppet/puppet-java',
        'puppet/puppet-kafka',
        'puppet/puppet-keepalived',
        'puppet/puppet-keystone',
        'puppet/puppet-kibana3',
        'puppet/puppet-kmod',
        'puppet/puppet-lib-file_concat',
        'puppet/puppet-logstash',
        'puppet/puppet-magnum',
        'puppet/puppet-manila',
        'puppet/puppet-memcached',
        'puppet/puppet-midonet',
        'puppet/puppet-midonet_openstack',
        'puppet/puppet-mistral',
        'puppet/puppet-module-data',
        'puppet/puppet-mongodb',
        'puppet/puppet-murano',
        'puppet/puppet-mysql',
        'puppet/puppet-n1k-vsm',
        'puppet/puppet-neutron',
        'puppet/puppet-nova',
        'puppet/puppet-nssdb',
        'puppet/puppet-ntp',
        'puppet/puppet-octavia',
        'puppet/puppet-opendaylight',
        'puppet/puppet-openstack_extras',
        'puppet/puppet-openstacklib',
        'puppet/puppet-oslo',
        'puppet/puppet-ovn',
        'puppet/puppet-pacemaker',
        'puppet/puppet-panko',
        'puppet/puppet-powerdns',
        'puppet/puppet-qdr',
        'puppet/puppet-rabbitmq',
        'puppet/puppet-redis',
        'puppet/puppet-remote',
        'puppet/puppet-rsync',
        'puppet/puppet-sahara',
        'puppet/puppet-sensu',
        'puppet/puppet-snmp',
        'puppet/puppet-ssh',
        'puppet/puppet-staging',
        'puppet/puppet-stdlib',
        'puppet/puppet-swift',
        'puppet/puppet-sysctl',
        'puppet/puppet-systemd',
        'puppet/puppet-tacker',
        'puppet/puppet-tempest',
        'puppet/puppet-timezone',
        'puppet/puppet-tomcat',
        'puppet/puppet-trove',
        'puppet/puppet-uchiwa',
        'puppet/puppet-vcsrepo',
        'puppet/puppet-veritas_hyperscale',
        'puppet/puppet-vitrage',
        'puppet/puppet-vlan',
        'puppet/puppet-vswitch',
        'puppet/puppet-xinetd',
        'puppet/puppet-zaqar',
        'puppet/puppet-zookeeper',
    ],
    'gerritbot': [
        'openstack/whitebox-tempest-plugin',
        'testbranching',
        'testproject',
    ]
}


def print_header(text):
    print("#" * (len(text) + 4))
    print("# " + text + " #")
    print("#" * (len(text) + 4))


def project_in_replication(project):
    for pattern in replication_patterns:
        if pattern.match(project) or \
                        project in IGNORED_PROJECTS['replication']:
            return True

    # This is tricky - we have some logic to adhere to here.
    # We don't replicate project sources, only their -distgit repositories.
    # Additionally, we also don't replicate puppet repositories.
    # Try to detect this without having to whitelist explicitely each and every
    # project.

    # "<project>-distgit-distgit" wouldn't be in projects
    if ("%s-distgit" % project in projects) or \
            (project.startswith('puppet') and project.endswith('distgit')):
        return True
    return False


def project_in_zuul(project):
    if project in zuul_projects or \
            project in IGNORED_PROJECTS['zuul']:
        return True
    return False


def project_in_gerritbot(project):
    if project in gerritbot_projects or \
            project in IGNORED_PROJECTS['gerritbot']:
        return True
    return False

###
# Retrieve Gerrit project list
###
# Gerrit's response is pretty-printed JSON but the first line is garbage, get
# rid of it
try:
    projects = requests.get(PROJECT_LIST)
    projects = json.loads(projects.text.replace(")]}'\n", ""))
except ValueError as e:
    print_header("Error when retrieving project list from Gerrit")
    print("HTTP: %s" % projects.status_code)
    print("Content: %s" % projects.text)
    raise e

###
# Retrieve Gerrit replication.config
###
# replication.config is really just a ini-like config file with leading spaces
# for the parameters, load it properly by stripping the whitespace
with open('gerrit/replication.config') as file:
    config = file.readlines()
replication = configparser.ConfigParser()
replication.readfp(StringIO(''.join([l.lstrip() for l in config])))

# What we're really interested from the replication.config file is the projects
# field which is a pattern we want to be matching against
replication_patterns = []
for section in replication.sections():
    try:
        pattern = re.compile(replication.get(section, 'projects'))
        replication_patterns.append(pattern)
    except configparser.NoOptionError:
        pass

###
# Retrieve list of projects in Gerritbot
###
gerritbot_projects = []
with open('gerritbot/channels.yaml') as f:
    config = yaml.load(f.read())
    irc_rdo = config['rdo']['projects']
    irc_opstools = config['centos-opstools']['projects']
    for project in irc_rdo + irc_opstools:
        gerritbot_projects.append(project)

###
# Retrieve list of projects in Zuul layout
###
zuul_files = glob.glob('zuul/*.yaml')
zuul_projects = []
for file in zuul_files:
    with open(file, 'r') as f:
        config = yaml.load(f.read())
    for project in config['projects']:
        zuul_projects.append(project['name'])


error = False
errors = collections.defaultdict(lambda: [])
for project in projects:
    # Check if project is replicated
    if not project_in_replication(project):
            error = True
            errors['replication'].append(project)

    # Check if project is in gerritbot
    if not project_in_gerritbot(project):
        error = True
        errors['gerritbot'].append(project)

    # Check if project is in zuul layout
    if not project_in_zuul(project):
        error = True
        errors['zuul'].append(project)

if errors['replication']:
    print_header("Projects not in Gerrit Replication")
    for e in sorted(errors['replication']):
        print(e)

if errors['zuul']:
    print_header("Projects not in Zuul Layout")
    for e in sorted(errors['zuul']):
        print(e)

if errors['gerritbot']:
    print_header("Projects not in Gerritbot")
    for e in sorted(errors['gerritbot']):
        print(e)

sys.exit(error)
