#!/bin/bash
set -x

FTPSRC='ftp://ftp.proftpd.org/distrib/source'
FTPVER=proftpd-1.3.5a.tar.gz

ADMINSRC=http://sourceforge.net/projects/proftpd-adm/files/latest/download

REPO=/root
WWWSRC=/var/www/html
FTPSRC=/ftp/incoming

MYSQLPWD=proftpd

MYSQLURL=http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm

PROFTP_CONF_OPT="--with-modules=mod_sql:mod_sql_mysql:mod_quotatab:mod_quotatab_sql \
--with-includes=/usr/include/mysql/ --with-libraries=/usr/lib64/mysql/"

function packages
{

yum install -y httpd php php-mysql

rpm -ivh ${MYSQLURL}
yum install -y wget mysql mysql-server mysql-devel
yum install -y glibc glibc-devel glibc-static
yum install -y zlib zlib-devel zlib-static

service mysqld start
}

function downloads
{
#wget $FTPSRC/$FTPVER -O $REPO/$FTPVER
wget ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.5a.tar.gz -O $REPO/$FTPVER
mkdir -p  $REPO/proftp
tar zxvf $REPO/$FTPVER -C $REPO/proftp --strip-components=1
}

function users
{
groupadd proftpd
useradd -g proftpd -m -d /home/proftpd proftpd
}

function ftp
{
cd $REPO/proftp && ./configure $PROFTP_CONF_OPT
cd $REPO/proftp && make 
cd $REPO/proftp && make install
}

function admin_package
{
mkdir -p /root/admin
mkdir -p $WWWSRC/admin

wget $ADMINSRC -O $REPO/admin.tar.gz
cd $REPO/ && tar zxvf admin.tar.gz -C $WWWSRC/admin --strip-components=1
sed -i "s/<database_password>/${MYSQLPWD}/" $WWWSRC/admin/misc/database_structure_mysql/db_structure.sql
sed -i "s/ TYPE=MyISAM//" $WWWSRC/admin/misc/database_structure_mysql/db_structure.sql
echo "grant all privileges on proftpd_admin.* to 'proftpd'@'localhost'" >> $WWWSRC/admin/misc/database_structure_mysql/db_structure.sql
mysql < $WWWSRC/admin/misc/database_structure_mysql/db_structure.sql 
}


function admin_configure
{
chmod o+w $WWWSRC/admin/configuration.xml 
cp $WWWSRC/admin/misc/sample_config/proftpd_quota.conf  /usr/local/etc/proftpd.conf 
sed -i 's/^SQLAuthTypes .*/SQLAuthTypes       Crypt Backend/' /usr/local/etc/proftpd.conf 
sed -i "s/<database_password>/${MYSQLPWD}/" /usr/local/etc/proftpd.conf 
sed -i "s/^DisplayFirstChdir/#DisplayFirstChdir/" /usr/local/etc/proftpd.conf 

pkill proftpd
proftpd -4
}

function ftp_repo
{
mkdir -p $FTPSRC
chmod o+w $FTPSRC
}

function restart_all
{
service httpd restart
pkill proftpd
proftpd -4
}

packages;
downloads;
users
ftp
admin_package
admin_configure
ftp_repo
restart_all
