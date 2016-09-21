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
module: win_dns_record
short_description: Creates DNS records on a Windows DNS server
description:
     - Creates DNS records on a Windows DNS server
options:
  name:
    description:
      - The hostname for the record.
    required: true
    default: null
  target:
    description:
      - The IP addres (for A records) or a hostname (for CNAMEs). If using a CNAME, this must be a FQDN. When creating and IP adddress is much be an IP address.
    required: true
	default: null
  zone_name:
    description:
      - The DNS zone name to add the record into.
    required: true
	default: null
  user_name:
    description:
      - The user name of a domain account that has permission to query and create a DNS record in the zone on the server.
    required: false
	default: null
  password:
    description:
      - The password for user_name.
    required: false
	default: null
  type:
    description:
      - The kind of DNS record to create. This can either be A or CNAME. It will default to 'A'.
    required: false
	default: A
author:
    - "Adam Bertram (@adbertram)"
'''

EXAMPLES = r'''
# This adds a A record in the zone demo.local.
$ ansible -i hosts -m win_dns_record -a "name='test' target='1.1.1.1' zone_name='demo.local' type='A'" all
# Playbook example
---
- name: Creates a DNS record
  hosts: all
  gather_facts: false
  tasks:
    - name: Creates a DNS record
      win_dns_record:
        name: test
        target: 1.1.1.1
        zone_name: demo.local
		type: A
'''