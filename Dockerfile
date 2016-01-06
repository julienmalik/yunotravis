FROM debian:jessie
MAINTAINER ljf "valentin@grimaud.me"

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C
ENV TERM=xterm

COPY ssh_key.pub /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

# See http://joeyh.name/blog/entry/docker_run_debian/
RUN rm -f /usr/sbin/policy-rc.d

# Allow amavis running even if uname return a bad hostname
#RUN apt-get update --quiet
#ADD 05-node_id /etc/amavis/conf.d/
#RUN chown root:root /etc/amavis/conf.d/05-node_id
#RUN chown root:root /etc/amavis
#RUN chown root:root /etc/amavis/conf.d
#RUN apt-get install -y --force-yes --no-install-recommends -o Dpkg::Options::="--force-confold" amavisd-new psmisc

# Yunohost Installation
#RUN apt-get install -y --force-yes --no-install-recommends wget ca-certificates
#RUN wget https://raw.githubusercontent.com/YunoHost/install_script/master/install_yunohostv2 -O /tmp/install_yunohostv2
ADD install_yunohostv2 /tmp/

# dnsmasq installation fails with :
# "dnsmasq: setting capabilities failed: Operation not permitted"
# Apply workaround of https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=514214
RUN echo user=root > /etc/dnsmasq.conf

RUN bash /tmp/install_yunohostv2 -a -d testing || true
RUN apt-get install -y --force-yes  || true

# The install script failed to start dovecot because it is already started
# Running separately the package doesn't work better because it is in trigger
# That's why there is these killall & apt-get install -y
# If you know how do it better don't hesitate to pull request
#RUN killall dovecot || true
#RUN apt-get install -y --force-yes  || true
#RUN killall dovecot || true
#RUN apt-get install -y --force-yes

# ADD firstrun /sbin/postinstall
# RUN chmod a+x /sbin/postinstall

EXPOSE 22 25 53/udp 80 443 465 993 5222 5269 5290
CMD /sbin/init
