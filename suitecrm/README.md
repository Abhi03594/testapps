# SuiteCRM Docker Image

This image provides a SuiteCRM Server. The image is based on php:apache docker image. It depends of a mysql database and can perform a silent install of SuiteCRM

# Quickstart
Run mysql database
Run suitecrm
```bash
docker pull zentekmx/suitecrm
docker run -d --name mysqldb -e MYSQL_USER=dbadmin -e MYSQL_PASSWORD=dbpasswd -e MYSQL_ALLOW_EMPTY_PASSWORD=false -e MYSQL_DATABASE=suitecrm mysql:5.7
docker run -d -p 80:80 --link mysqldb -e SYSTEM_NAME=MyCRM -e DATABASE_TYPE=mysql -e DATABASE_HOST=mysqldb -e DATABASE_NAME=suitecrm -e DB_ADMIN_USERNAME=dbadmin -e DB_ADMIN_PASSWORD=dbpasswd -e SITE_USERNAME=admin -e SITE_PASSWORD=password zentekmx/suitecrm
```

# Features
 - Silent install
 - Exposed volumes
 - Image size of ~800MB

# Usage
There are several parameters available to configure your CRM instance, you can use the following docker compose template:
```
version: '3'

services:
  mysqldb:
    image: mysql:5.7
    environment:
    - MYSQL_USER=dbadmin
    - MYSQL_PASSWORD=dbpasswd
    - MYSQL_DATABASE=suitecrmdb

  suitecrm:
    image: zentekmx/suitecrm:7.9
    depends_on:
    - mysql
    ports:
    - "80:80"
    environment:
    - CURRENCY_ISO4217=MXN
    - CURRENCY_NAME=MX Peso
    - DATE_FORMAT=d-m-Y
    - EXPORT_CHARSET=ISO-8859-1
    - DEFAULT_LANGUAGE=en_us
    - DATABASE_TYPE=mysql
    - DATABASE_HOST=mysqldb
    - DB_ADMIN_PASSWORD=secret
    - DB_ADMIN_USERNAME=ztadmin
    - DATABASE_NAME=suitecrmdb
    - SITE_USERNAME=admin
    - SITE_PASSWORD=password
    - SITE_URL=http://localhost
    - SYSTEM_NAME=Zentek CRM
```

# Exposed ports
 * 80

# Exposed volumes
 * /var/www/html/upload
 * /var/www/html/conf.d

