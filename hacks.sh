#!/bin/bash

set -x

dockerex() {
  docker exec -i ${CONTAINER_ID} "$@"
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
dockerex ln -s /bin/true /etc/init.d/yunohost-firewall
dockerex ln -s /bin/true /etc/init.d/yunohost-firewall
# Since we put aside iptables, fail2ban becomes useless too. Make it quiet
dockerdivertexe /etc/init.d/fail2ban
# Glances generates errors
dockerdivertexe /etc/init.d/glances
# In regular Yunohost installation, dnsmasq is reloaded via systemctl with 'service dnsmasq reload'
# In docker, we fallback on the sysvinit script, which does not support reload, only force-reload
# Just put it aside since we don't really care here
dockerdivertexe /etc/init.d/dnsmasq
# usdisk-glue is normally started via systemd, and does not ship a sysvinit script replacement
dockerex ln -s /bin/true /etc/init.d/udisks-glue

# Temporary FIX: try to not use "tr" to avoid https://dev.yunohost.org/issues/149
#dockerex sed -i 's@randpass 10 0@openssl rand -base64 16@g' /usr/share/yunohost/hooks/conf_regen/34-mysql
#dockerex sed -i "s@echo \$mysql_password | sudo tee /etc/yunohost/mysql@echo \$mysql_password > /etc/yunohost/mysql@g" /usr/share/yunohost/hooks/conf_regen/34-mysql

dockerex sh -c 'cat > /usr/share/yunohost/hooks/conf_regen/34-mysql' < 34-mysql
dockerex cat /usr/share/yunohost/hooks/conf_regen/34-mysql

# Temporary FIX: skip mysql completely, to see if this is the one stalling the postinstall
# dockerex rm /usr/share/yunohost/hooks/conf_regen/34-mysql
