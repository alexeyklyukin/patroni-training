#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/01norecommend
echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/01norecommend

apt-get update
apt-get upgrade -y

apt-get install -y curl ca-certificates less locales jq vim git sudo

## Make sure we have a en_US.UTF-8 locale available
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

apt-get install -y postgresql-common
sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf

version=10

# Install PostgreSQL binaries and contrib
apt-get install -y postgresql-${version} postgresql-client-${version} postgresql-contrib-${version}

ETCDVERSION=2.3.7
# install etcd
curl -sL https://github.com/coreos/etcd/releases/download/v${ETCDVERSION}/etcd-v${ETCDVERSION}-linux-amd64.tar.gz \
 | tar xz -C /bin --strip=1 --wildcards --no-anchored etcdctl etcd

# install pip
apt-get install -y python3 python3-wheel python3-pip python3-psycopg2 python3-setuptools python3-etcd python3-psutil python3-requests python3-yaml python3-pygments python3-cdiff python3-idna python3-certifi python3-tz python3-click python3-prettytable python3-tzlocal python3-more-itertools python3-py python3-pluggy python3-dateutil

# install patroni and pg_view
pip3 install httpie dumb-init 'git+https://github.com/zalando/patroni.git@master#egg=patroni[etcd]' 'git+https://github.com/zalando/pg_view.git@master#egg=pg-view'

# clean up
rm -rf /var/lib/apt/lists/*

echo "export PATH=\$PATH:/usr/lib/postgresql/10/bin
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export EDITOR=vim" >> /etc/bash.bashrc

cd /var/lib/postgresql

for i in {0..2}; do
    curl -Os https://raw.githubusercontent.com/zalando/patroni/master/postgres${i}.yml
done
# uncomment the archive and recovery commands and related options.
sed -i 's/^#\(\s*\(archive\|restore\|recovery\)_.*$\)/\1/g' postgres?.yml
sed 's/archive_mode:.*/max_connections: 100\n        &/' postgres?.yml
mkdir -p .config/patroni
ln -s ../../postgres0.yml .config/patroni/patronictl.yaml
chown -R postgres: .
etcd &>/tmp/etcd.log &
