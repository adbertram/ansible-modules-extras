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
module: win_windows_update_agent
short_description: Changes various settings for the local Windows Update Agent
description:
     - Changes various settings for the local Windows Update Agent
options:
  enabled:
    description:
      - This will enable or disable the WUA.
    required: false
    choices:
      - true
      - false
    default: null
  accept_trusted_publisher_certs:
    description:
      - To trust software publisher certs.
    required: false
    choices:
      - true
      - false
    default: null
  elevate_non_admins:
    description:
      - Elevate non-admin accounts.
    required: false
    choices:
      - true
      - false
    default: null
  target_group:
    description:
      - The WSUS target group.
    required: false
  windows_update_server_url:
    description:
      - The WSUS server URL.
    required: false
    default: null
  windows_update_status_server_url:
    description:
      - The WSUS server status URL
    required: false
    default: null
  automatic_update_options:
    description:
      - What action to take for new downloads.
    choices:
      - notify_before_download
      - auto_download_and_notify
      - auto_download_and_schedule
      - user_configurable
    required: false
    default: null
  auto_install_minor_updates:
    description:
      - Auto install minor updates
    required: false
    choices:
      - true
      - false
    default: null
  detection_frequency:
    description:
      - Detection frequency
    required: false
    default: null
  no_auto_reboot_with_logged_on_users:
    description:
      - Will not automatically reboot when users are logged on.
    required: false
    choices:
      - true
      - false
    default: null
  no_auto_update:
    description:
      - Will not automatically update.
    required: false
    choices:
      - true
      - false
    default: null
  reboot_launch_timeout:
    description:
      - How long before a reboot is forced.
    required: false
  reboot_warning_timeout:
    description:
      - The time in seconds to warn before a reboot.
    required: false
    default: null
  reschedule_wait_time:
    description:
      - Reschedule wait time.
    required: false
  scheduled_install_day:
    description:
      - The frequency scheduled installs are done.
    choices:
      - every_day
      - monday
      - tuesday
      - wednesday
      - thursday
      - friday
      required: false
      default: null
  scheduled_install_time:
    description:
      - The time to install scheduled installs.
    required: false
    default: null
  update_source:
    description:
      - Update source.
    required: false
    default: null
author:
    - "Adam Bertram (@adbertram)"
'''

EXAMPLES = r'''
# This disables the WUA.
$ ansible -i hosts -m win_windows_update_agent -a "enabled=false" all
# Playbook example
---
- name: Disable WUA
  hosts: all
  gather_facts: false
  tasks:
    - name: Disable WUA
      win_windows_update_agent:
        enabled: false
'''