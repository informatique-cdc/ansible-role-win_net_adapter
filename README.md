# win_net_adapter - Sets one or more interface specific DNS client configurations on a Windows host

## Synopsis

* This Ansible module allows to set one or more the interface specific DNS client configurations.
* Uses the connection specific suffix as filter to select network card to update.

## Parameters

| Parameter     | Choices/<font color="blue">Defaults</font> | Comments |
| ------------- | ---------|--------- |
|__suffix_filter__<br><font color="purple">string</font></font> / <font color="red">required</font> |  | Specifies the DNS suffixes or the network profile names which will be used to filter the network adapter to configure. |
|__new_name__<br><font color="purple">string</font></font> |  | Specifies the new name and interface alias of the network adapter.<br>The module adds index as '_I(index)' to the name when more netcard are using the same DNS suffixe.<br>For example, if _new_name_ = `OOB` then netcard1 will be named `OOB`, netcard2 will be named `OOB_1` and netcard3 will be name `OOB_2`. |
|__register_ip_address__<br><font color="purple">boolean</font></font> | __Choices__: <ul><li>no</li><li>yes</li></ul> | Indicates whether the IP address for this connection is to be registered.<br>Updates the option 'Register this connection's addresses in DNS' in DNS client tab properties. |
|__reset_server_addresses__<br><font color="purple">boolean</font></font> | __Choices__: <ul><li>no</li><li>yes</li></ul> | Resets the DNS server IP addresses to the default value. |
|__server_addresses__<br><font color="purple">string</font></font> |  | Specifies a list of DNS server IP addresses to set for the interface. |
|__tcpip6__<br><font color="purple">boolean</font></font> | __Choices__: <ul><li>no</li><li>yes</li></ul> | Specifies to enable or to disable the IPv6 binding to the network adapter. |

## Examples

```yaml
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

```

## Authors

* Stéphane Bilqué (@sbilque) Informatique CDC

## License

This project is licensed under the Apache 2.0 License.

See [LICENSE](LICENSE) to see the full text.
