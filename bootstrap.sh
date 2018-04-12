#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/01norecommend
echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/01norecommend

apt-get update
apt-get upgrade -y

apt-get install -y cron curl ca-certificates less locales jq vim git gcc gdb sudo strace

## Make sure we have a en_US.UTF-8 locale available
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8


export DISTRIB_CODENAME=$(sed -n 's/DISTRIB_CODENAME=//p' /etc/lsb-release)
# Add PGDG repositories
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${DISTRIB_CODENAME}-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && echo "deb-src http://apt.postgresql.org/pub/repos/apt/ ${DISTRIB_CODENAME}-pgdg main" >> /etc/apt/sources.list.d/pgdg.list \
    && curl -s -o - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -y postgresql-common \
    && sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf

version=10

# Install PostgreSQL binaries, contrib, plperl and plpython
apt-get install --allow-downgrades -y postgresql-${version} postgresql-${version}-dbg \
    postgresql-client-${version} postgresql-contrib-${version} \
    postgresql-plpython-${version} postgresql-plperl-${version} \
    libpq5=$version* libpq-dev=$version* postgresql-server-dev-${version}

ETCDVERSION=2.3.7
# install etcd
curl -sL https://github.com/coreos/etcd/releases/download/v${ETCDVERSION}/etcd-v${ETCDVERSION}-linux-amd64.tar.gz \
 | tar xz -C /bin --strip=1 --wildcards --no-anchored etcdctl etcd

# install pip
apt-get install -y python-dev python-wheel python-pip python-psycopg2 --upgrade

# install patroni and pg_view
pip install setuptools pip --upgrade
pip install patroni[etcd] 'git+https://github.com/zalando/pg_view.git@master#egg=pg-view'

echo "PATH=\$PATH:/usr/lib/postgresql/10/bin" > /var/lib/postgresql/.profile
mkdir -p /var/lib/postgresql/patroni
cd /var/lib/postgresql/patroni
for i in {0..2}; do
    curl -Os https://raw.githubusercontent.com/zalando/patroni/master/postgres${i}.yml
    # uncomment the archive and recovery commands and related options.
    sed -i 's/^#\(\s*\(archive\|restore\|recovery\)_.*$\)/\1/g' postgres${i}.yml
done
chown -R postgres: /var/lib/postgresql/patroni
etcd &>/tmp/etcd-logs/etcd.log &

