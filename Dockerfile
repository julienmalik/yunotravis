FROM debian:jessie
MAINTAINER ju "ju+docker@paraiso.me"

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C
ENV TERM xterm

# See http://joeyh.name/blog/entry/docker_run_debian/
RUN rm -f /usr/sbin/policy-rc.d

# Yunohost Installation
#RUN apt-get install -y --force-yes --no-install-recommends wget ca-certificates
#RUN wget https://raw.githubusercontent.com/YunoHost/install_script/master/install_yunohostv2 -O /tmp/install_yunohostv2
ADD install_yunohostv2 /tmp/

# dnsmasq installation fails with :
# "dnsmasq: setting capabilities failed: Operation not permitted"
# Apply workaround of https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=514214
RUN echo user=root > /etc/dnsmasq.conf

RUN apt-get update
RUN apt-get -y install mysql-server
RUN bash /tmp/install_yunohostv2 -a -d testing || true
RUN apt-get install -y --force-yes  || true

EXPOSE 22 25 53/udp 80 443 465 993 5222 5269 5290
CMD /sbin/init
