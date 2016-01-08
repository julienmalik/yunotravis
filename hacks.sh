#!/bin/bash

set -x

dockerex() {
  docker exec -t -i ${CONTAINER_ID} "$@"
}

# Setup diversion for executable so that they always exit gracefully
dockerdivertexe() {
  dockerex dpkg-divert --rename "$1"
  dockerex ln -s /bin/true "$1"
}

# Docker handles the firewall itself, and we don't really care here
dockerdivertexe /sbin/iptables
dockerdivertexe /sbin/ip6tables
# dovecot fails to start in the container (TODO : figure out why)
dockerdivertexe /etc/init.d/dovecot
# avahi-daemon fails to start in the container (TODO : figure out why)
dockerdivertexe /etc/init.d/avahi-daemon
# systemctl is used directly by yunohost to restart some services,
# and this generates 'Failed to get D-Bus connection: Unknown error -1'
# let's make it quiet
dockerdivertexe /bin/systemctl
# YunoHost deploys a yunohost-firewall systemd unit, but no sysvinit equivalent.
# so calls to 'service yunohost-firewall command" error out with :
# update-rc.d: error: cannot find a LSB script for yunohost-firewall
# yunohost-firewall: unrecognized service
ln -s /bin/true /etc/init.d/yunohost-firewall


# Temporary FIX: try to not use "tr" to avoid https://dev.yunohost.org/issues/149
# dockerex sed -i 's@randpass 10 0@openssl rand -base64 16@g' /usr/share/yunohost/hooks/conf_regen/34-mysql

# Temporary FIX: skip mysql completely, to see if this is the one stalling the postinstall
dockerex rm /usr/share/yunohost/hooks/conf_regen/34-mysql
