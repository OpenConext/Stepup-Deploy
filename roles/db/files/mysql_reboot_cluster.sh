#!/usr/bin/env bash

# Reboot a MariaDB Gallera cluster node
#
# Usage: mysql_reboot_cluster.sh "<mysql root password>"
#
# When a node is the only node (i.e. first) node in a cluster it must
# be bootstrapped. For MariaDB-Gallera-server this is done by using "bootstrap" instead of "start"

root_password=$1

if [ -z ${root_password} ]; then
   echo "Usage $0 <root password>"
   exit 1
fi


# Get cluster size
echo -n "Getting cluster size... "
cluster_size=`mysql -u root -p"${root_password}" -e 'SHOW STATUS LIKE "wsrep_cluster_size";' -B -N | cut -f2`
res=$?
if [ ${res} == 0 ]; then
   echo "OK. wsrep_cluster_size=${cluster_size}"
else
   echo "Failed"
   exit 1
fi


# Choose restart method based on cluter size
if [ "${cluster_size}" -gt "1" ]; then
    echo -n "Restarting mysql... "
    /sbin/service mysql restart
    res=$?
elif [ "${cluster_size}" -eq "1" ]; then
    echo -n "Restarting mysql with the 'bootstrap' option... "
    /sbin/service mysql stop
    /sbin/service mysql bootstrap
    res=$?
else
    echo "Expected cluster size >= 1";
    exit 1
fi

if [ ${res} == 0 ]; then
   echo "OK"
else
   echo "Failed"
   exit 1
fi

exit 0