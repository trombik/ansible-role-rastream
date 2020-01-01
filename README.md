# `trombik.rastream`

`ansible` role for `rastream`.

This role installs custom startup script because official packages do not
create one.

# Requirements

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `rastream_package` | Package name of `rastream` | `{{ __rastream_package }}` |
| `rastream_service` | Service name of `rastream` | `{{ __rastream_service }}` |
| `rastream_extra_packages` | A list of extra packages to install | `[]` |
| `rastream_user` | User name of `rastream` | `{{ __rastream_user }}` |
| `rastream_group` | Group name of `rastream` | `{{ __rastream_group }}` |
| `rastream_log_dir` | Path to log directory | `{{ __rastream_log_dir }}` |
| `rastream_extra_groups` | A list of extra group that `rastream` user should belong to | `[]` |
| `rastream_flags` | See below | `""` |


## `rastream_flags`

This variable is used for overriding defaults for startup scripts. In Debian
variants, the value is the content of `/etc/default/rastream`. In RedHat
variants, it is the content of `/etc/sysconfig/rastream`. In FreeBSD, it
is the content of `/etc/rc.conf.d/rastream`. In OpenBSD, the value is
passed to `rcctl set rastream`.

## Debian

| Variable | Default |
|----------|---------|
| `__rastream_service` | `rastream` |
| `__rastream_package` | `argus-clients` |
| `__rastream_user` | `argus` |
| `__rastream_group` | `argus` |

# Dependencies

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - trombik.argus
    - trombik.argus_clients
    - ansible-role-rastream
  pre_tasks:
    - name: Dump all hostvars
      debug:
        var: hostvars[inventory_hostname]
  post_tasks:
    - name: List all services (systemd)
      # workaround ansible-lint: [303] service used in place of service module
      shell: "echo; systemctl list-units --type service"
      changed_when: false
      when:
        - ansible_os_family == 'RedHat' or ansible_os_family == 'Debian'
    - name: list all services (FreeBSD service)
      # workaround ansible-lint: [303] service used in place of service module
      shell: "echo; service -l"
      changed_when: false
      when:
        - ansible_os_family == 'FreeBSD'
  vars:
    os_argus_flags:
      Debian: |
        ARGUS_OPTIONS="-F {{ argus_config_file }}"
    argus_flags: "{{ os_argus_flags[ansible_os_family] }}"

    os_interface:
      FreeBSD: em0
      OpenBSD: em0
      Debian: eth0
      RedHat: eth0
    argus_config: |
      ARGUS_FLOW_TYPE="Bidirectional"
      ARGUS_FLOW_KEY="CLASSIC_5_TUPLE"
      {% if ansible_os_family != 'Debian' and ansible_os_family != 'RedHat' %}
      # XXX the unit file expects the command not to fork
      ARGUS_DAEMON=yes
      {% endif %}
      ARGUS_ACCESS_PORT=561
      ARGUS_BIND_IP="127.0.0.1"
      ARGUS_INTERFACE={{ os_interface[ansible_os_family] }}
      ARGUS_GO_PROMISCUOUS=yes
      ARGUS_SETUSER_ID={{ argus_user }}
      ARGUS_SETGROUP_ID={{ argus_group }}
      ARGUS_OUTPUT_FILE={{ argus_log_dir}}/argus.ra
      ARGUS_FLOW_STATUS_INTERVAL=60
      ARGUS_MAR_STATUS_INTERVAL=300
      ARGUS_DEBUG_LEVEL=1
      ARGUS_FILTER="ip"
      ARGUS_SET_PID=yes
      ARGUS_PID_PATH=/var/run

    os_rastream_flags:
      OpenBSD: ""
      FreeBSD: ""
      Debian: |
        RASTREAM_OPTIONS="-S 127.0.0.1 -M time 1m -w {{ rastream_log_dir }}/%Y/%m/%d/%H.%M.%S.ra"
      RedHat: ""
    rastream_flags: "{{ os_rastream_flags[ansible_os_family] }}"
    rastream_package: ""
    rastream_user: "{{ argus_user }}"
    rastream_group: "{{ argus_group }}"
    rastream_log_dir: "{{ argus_log_dir }}/rastream"
```

# License

```
Copyright (c) 2020 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>
