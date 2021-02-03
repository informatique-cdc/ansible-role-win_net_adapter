#!/usr/bin/python
# -*- coding: utf-8 -*-

# This is a windows documentation stub.  Actual code lives in the .ps1
# file of the same name.

# Copyright 2020 Informatique CDC. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

from __future__ import absolute_import, division, print_function
__metaclass__ = type


ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: win_net_adapter
short_description: Sets one or more interface specific DNS client configurations on a Windows host
author:
    - Stéphane Bilqué (@sbilque) Informatique CDC
description:
    - This Ansible module allows to set one or more the interface specific DNS client configurations.
    - Uses the connection specific suffix as filter to select network card to update.
options:
    suffix_filter:
        description:
            - Specifies the DNS suffixes or the network profile names which will be used to filter the network adapter to configure.
        required: yes
        type: str
    new_name:
        description:
            - Specifies the new name and interface alias of the network adapter.
            - The module adds index as '_I(index)' to the name when more netcard are using the same DNS suffixe.
            - For example, if I(new_name) = C(OOB) then netcard1 will be named C(OOB), netcard2 will be named C(OOB_1) and netcard3 will be name C(OOB_2).
        type: str
    register_ip_address:
        description:
            - Indicates whether the IP address for this connection is to be registered.
            - Updates the option 'Register this connection's addresses in DNS' in DNS client tab properties.
        type: bool
    reset_server_addresses:
        description:
            - Resets the DNS server IP addresses to the default value.
        type: bool
    server_addresses:
        description:
            - Specifies a list of DNS server IP addresses to set for the interface.
        type: str
    tcpip6:
        description:
            - Specifies to enable or to disable the IPv6 binding to the network adapter.
        type: bool
'''

EXAMPLES = r'''
---
- name: Should renames a netcard
  win_net_adapter:
    suffix_filter: oob*
    new_Name: OOB

- name: Should disable the tcp ipv6 protocole
  win_net_adapter:
    suffix_filter: oob*
    tcpip6: false

- name: Should return the register_ip_address state
  win_net_adapter:
    suffix_filter: oob*
    register_ip_address: false

- name: Should reset the server addresses
  win_net_adapter:
    suffix_filter: consoto.com
    reset_server_addresses: true

- name: Should change the server addresses
  win_net_adapter:
    suffix_filter: consoto.com
    server_addresses: 8.8.8.8,8.8.8.4

- name: Should renames and configure multiple netcards
  win_net_adapter:
    suffix_filter: consoto.local,*.consoto.local
    new_name: OOB
    reset_server_addresses: true
    register_ip_address: false

- name: Should disable the tcp ipv6 protocole on all cards
  win_net_adapter:
    suffix_filter: '*'
    tcpip6: false
'''