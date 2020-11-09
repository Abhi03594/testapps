#!/bin/bash

cd /opt/cacti/plugins
# download the source
git clone -b master https://github.com/Cacti/plugin_thold.git
# rename it to thold, yes it matters...
mv plugin_thold thold

touch /opt/cacti/log/cacti.log
chown -R www-data:www-data /opt/cacti/

mv /etc/mysql/my.cnf /etc/mysql/my.cnf-bkup
echo "
[mysqld]

max_heap_table_size = 1073741824
max_allowed_packet = 16777216
tmp_table_size = 500M
join_buffer_size = 1000M
innodb_file_format=Barracuda
innodb_large_prefix=1
innodb_io_capacity=5000
innodb_buffer_pool_instances=62
innodb_buffer_pool_size = 7811M
innodb_doublewrite = ON
innodb_flush_log_at_timeout = 10
innodb_read_io_threads = 32
innodb_write_io_threads = 16
collation-server = utf8mb4_unicode_ci
character-set-server = utf8mb4
" > /etc/mysql/my.cnf


#Initial conf for mysql
mysql_install_db
#for configuriing database
/usr/bin/mysqld_safe &

 sleep 3s 
  
 mysqladmin -u root password mysqlpsswd
 mysqladmin -u root -pmysqlpsswd reload
 mysqladmin -u root -pmysqlpsswd create cacti
 echo "GRANT ALL ON cacti.* TO cacti@localhost IDENTIFIED BY '9PIu8AbWQSf8'; flush privileges; " | mysql -u root -pmysqlpsswd 
 echo "GRANT SELECT ON mysql.time_zone_name TO cacti@localhost IDENTIFIED BY '9PIu8AbWQSf8'; flush privileges; " | mysql -u root -pmysqlpsswd 
 
 mysql -u root -pmysqlpsswd cacti < /opt/cacti/cacti.sql
 mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -pmysqlpsswd mysql
 
 #to fix error relate to ip address of container apache2
 echo "ServerName localhost" | tee /etc/apache2/conf-available/fqdn.conf
 ln -s /etc/apache2/conf-available/fqdn.conf /etc/apache2/conf-enabled/fqdn.conf
 
 # to create a link for the cacti web directory
 ln -s /opt/cacti/ /var/www/html/cacti
 
 #configure poller Crontab
 echo "* * * * * www-data php /opt/cacti/poller.php > /dev/null 2>&1" >> /etc/crontab 

mysqladmin shutdown
sleep 2s


cd /opt/
wget http://www.cacti.net/downloads/spine/cacti-spine-latest.tar.gz
ver=$(tar -tf cacti-spine-latest.tar.gz | head -n1 | tr -d /)
tar -xvf /opt/cacti-spine-latest.tar.gz
cd /opt/$ver/
./bootstrap 
./configure
make
make install
chown root:root /usr/local/spine/bin/spine
chmod +s /usr/local/spine/bin/spine
rm ../cacti-spine-latest.tar.gz
rm -R /opt/$ver

#make backup copy for Volume 
mkdir -p /var/backup
cp -Rp /var/lib/mysql /var/backup
cp -Rp /opt/cacti/plugins /var/backup
cp -Rp /var/log  /var/backup
