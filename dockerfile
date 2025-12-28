FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker
STOPSIGNAL SIGRTMIN+3

RUN apt-get update && apt-get install -y \
    systemd systemd-sysv dbus dbus-user-session \
    apache2 \
    libapache2-mod-auth-gssapi \
    libapache2-mod-lookup-identity \
    sssd sssd-tools sssd-ad sssd-krb5 sssd-dbus \
    libnss-sss libpam-sss \
    krb5-user \
    samba-common-bin winbind libnss-winbind \
    realmd adcli oddjob oddjob-mkhomedir \
    net-tools iputils-ping dnsutils tcpdump nano vim \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/systemd/system.conf.d && \
    printf "[Manager]\nDefaultTimeoutStartSec=30s\nDefaultTimeoutStopSec=30s\n" \
    > /etc/systemd/system.conf.d/timeouts.conf

CMD ["/sbin/init"]
