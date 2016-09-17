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
module: win_dnsServerAddress
version_added: "2.2"
short_description: Sets DNS server addresses on a network adapter
description:
     - Sets DNS server addresses on a network adapter
options:
  interfaceAlias:
    description:
      - The network adapter alias to use. This can be found by running the PowerShell command Get-NetIpInterface.
    required: true
    default: null
  state:
    description:
      - State of the features or roles on the system
    required: false
    choices:
      - present
      - absent
    default: present
  address:
    description:
      - The single or comma-separated list of IPv4 or IPv6 address(es) that indicate the DNS server search order for the interface.
    default: null
    required: true
  addressFamily:
    description:
      - The IP address class of the DNS server address(es).
    choices:
      - ipv4
      - ipv6
    default: null
    required: false
author:
    - "Adam Bertram (@adbertram)"
'''

EXAMPLES = r'''
# This sets the primary DNS server address to 4.4.4.4 and the secondary to 8.8.8.8 on the Ethernet network adapter.
$ ansible -i hosts -m win_dnsServerAddress -a "address='4.4.4.4','8.8.8.8' interfaceAlias='Ethernet'" all
# Playbook example
---
- name: Set DNS server address search order
  hosts: all
  gather_facts: false
  tasks:
    - name: Set DNS server address search order
      win_dnsServerAddress:
        address: "4.4.4.4","8.8.8.8"
        state: present
        interfaceAlias: Ethernet
'''