dlrn Report
===========

Ansible role to report job results to dlrn.

Requirements
------------

Running his role effectively will require credentials to report to drln.

Role Variables
--------------

- workspace: <"{{ ansible_user_dir }}/workspace">
- ci_config_repo: <path to 'review.rdoproject.org/config'>

Dependencies
------------

This playbook depends on the playbooks and roles in opendev.org/openstack/tripleo-ci.

Example Playbook
----------------

Playbook to setup variables in a pre-run and then report in a post-run:

- name: Set up reporting variables
  hosts: localhost
  include_role:
    name: dlrn-report
    tasks_from: dlrn-vars-setup.yml

- name: Report results after job run
  hosts: localhost
  include_role:
    name: dlrn-report
    tasks_from: dlrn-report-results.yml

License
-------

Apache

Author Information
------------------

RDO-CI Team

