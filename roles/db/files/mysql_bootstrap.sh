#/bin/bash

# Bootstrap a mysql installation on CentOS / Redhat
# This is the non interactive and idempotent equivalent of the "mysql_secure_installation" installation script
# - Set a password on the root accounts
# - remove test database
# - remove anonymous users
#
# Usage: mysql_bootstrap.sh "<mysql root password>"


mysql_root_password=$1

if [ -z ${mysql_root_password} ]; then
   echo "Usage $0 <mysql root password>"
   exit 1
fi

#Test login as user root to localhost without password
#Note there are more root accounts beside @localhost: @127.0.0.1, @::1 and @<hostname>
#We don't test for these below, only localhost.
out_err=$( mysql --user=root --host=localhost --password= -e exit 2>&1 )
# May return (MariaDB 10 om CentOS 7):
# Service down: ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/lib/mysql/mysql.sock' (2 "No such file or directory")
# Wrong password: ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)
res=$?

if [ $res == 0 ]; then
   echo "Root access without password is allowed to localhost. Setting new root password for all root users."
   mysql --user=root --password= -e "UPDATE mysql.user SET Password = PASSWORD('${mysql_root_password}') WHERE User = 'root'; FLUSH PRIVILEGES;"
   res=$?
   if [ $res == 1 ]; then
      echo "Error setting new mysql password"
      exit 1;
   fi
   echo "Set new password for mysql user root"
elif [[ ${out_err} ==  "ERROR 1045 (28000)"* ]]; then
   # Access denied for user root. There is a password set
   echo "Mysql root account has a password set"
else
   echo "Unexpected error from mysql:"
   echo ${out_err}
  exit 1
fi

# Fix any root acounts that we may have missed
echo -n "Securing all root accounts... "
mysql -u root -p${mysql_root_password} -e "UPDATE mysql.user SET Password = PASSWORD('${mysql_root_password}') WHERE User = 'root'; FLUSH PRIVILEGES;"
res=$?
if [ ${res} == 0 ]; then
   echo "OK"
else
   echo "Failed"
   exit 1
fi


echo -n "Removing anonymous users (if any)... "
mysql -u root -p"${mysql_root_password}" -e "DELETE FROM mysql.user WHERE User = ''; FLUSH PRIVILEGES;"
res=$?
if [ ${res} == 0 ]; then
   echo "OK"
else
   echo "Failed"
   exit 1
fi


echo -n "Removing test schema/database (if any)... "
mysql -u root -p"${mysql_root_password}" -e "DROP DATABASE IF EXISTS test;"
res=$?
if [ ${res} == 0 ]; then
   echo "OK"
else
   echo "Failed"
   exit 1
fi


exit 0