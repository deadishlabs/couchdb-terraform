#!/bin/bash
# Install script for single node CouchDB instance
# Maintainer: https://github.com/deadishlabs

set -e

IPADDR=`ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1`

# #cleanup
rm -rf /var/log/couchdb
rm -rf /home/couchdb
rm -rf /etc/sv/couchdb/
rm -rf /etc/service/couchdb
rm -rf apache-couchdb-2.1.1*


sudo apt-get update || true
sudo apt-get --no-install-recommends -y install \
    build-essential pkg-config runit erlang \
    libicu-dev libmozjs185-dev libcurl4-openssl-dev

wget https://www.apache.org/dist/couchdb/source/2.1.1/apache-couchdb-2.1.1.tar.gz

tar -xvzf apache-couchdb-2.1.1.tar.gz
cd apache-couchdb-2.1.1/
./configure && make release

sudo adduser --system \
        --no-create-home \
        --shell /bin/bash \
        --group --gecos \
        "CouchDB Administrator" couchdb

mkdir /home/couchdb
sudo cp -R rel/couchdb/* /home/couchdb

#give instance unique couchdb node name based off IP
sed -i 's/^-name .*/-name couchdb@'$IPADDR'/' /home/couchdb/etc/vm.args

sudo chown -R couchdb:couchdb /home/couchdb
sudo find /home/couchdb -type d -exec chmod 0770 {} \;
sudo sh -c 'chmod 0644 /home/couchdb/etc/*'

sudo mkdir /var/log/couchdb
sudo chown couchdb:couchdb /var/log/couchdb

sudo mkdir /etc/sv/couchdb
sudo mkdir /etc/sv/couchdb/log

cat > run << EOF
#!/bin/sh
export HOME=/home/couchdb
exec 2>&1
exec chpst -u couchdb /home/couchdb/bin/couchdb
EOF

cat > log_run << EOF
#!/bin/sh
exec svlogd -tt /var/log/couchdb
EOF

sudo mv ./run /etc/sv/couchdb/run
sudo mv ./log_run /etc/sv/couchdb/log/run

sudo chmod u+x /etc/sv/couchdb/run
sudo chmod u+x /etc/sv/couchdb/log/run

sudo ln -s /etc/sv/couchdb/ /etc/service/couchdb

sleep 5
sudo sv status couchdb

sed -i 's/^bind_address =.*/bind_address = 0.0.0.0/' /home/couchdb/etc/default.ini
sed -i 's/^require_valid_user =.*/require_valid_user = true/' /home/couchdb/etc/default.ini

echo "-kernel inet_dist_listen_min 9100
-kernel inet_dist_listen_max 9200" >> /home/couchdb/etc/vm.args

sv restart couchdb
