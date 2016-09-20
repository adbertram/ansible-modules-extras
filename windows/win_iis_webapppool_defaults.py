#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2016, Adam Bertram (@adbertram)
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# this is a windows documentation stub.  actual code lives in the .ps1
# file of the same name

DOCUMENTATION = '''
---
module: win_iis_webapppool_defaults
=======
module: win_iis_webapppooldefaults
version_added: "2.2"
short_description: Sets IIS settings for the application pool defaults
description:
     - Sets IIS settings for the application pool defaults
options:
  idleTimeout:
    description:
      - idleTimeout
    required: false
    default: present
  logEventOnRecycle:
    description:
      - logEventOnRecycle
    default: null
    required: false
  startMode:
    description:
      - startMode
    choices:
      - AlwaysRunning
      - OnDemand
    default: null
    required: false
author:
    - "Adam Bertram (@adbertram)"
'''

RETURN = """

"""

EXAMPLES = r'''
# This sets the idleTime on all application pools by default o 00:00:00
$ ansible -i hosts -m win_iis_webapppool_defaults -a "idleTimeout=00:00:00" all
# Playbook example
---
- name: Set idleTimeout to 00:00:00
  hosts: all
  gather_facts: false
  tasks:
    - name: Set idleTimeout to 00:00:00
      win_iis_webapppool_defaults:
        address: "00:00:00"
'''