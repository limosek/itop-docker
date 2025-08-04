# iTop docker
This repository is for automatic iTop deplotment by docker.
This is standalone iTop repo, you need mariadb container for db.
It installs and preconfigure iTop together with IPAM module.

## How to use
Easiest way how to run is to use docker-compose.yml.
Change passwords in there to match your site.
Change URL to match your actual iTop URL.

```
version: "3.9"
services:
  db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: "___rootpw___"
      MYSQL_DATABASE: "itop"
      MYSQL_USER: "itop"
      MYSQL_PASSWORD: "___itoppw___"
    volumes:
      - db:/var/lib/mysql

  itop:
    image: limosek/itop:latest
    depends_on:
      - db
    environment:
      DBUSER: itop
      DBPASSWORD: "___itoppw___"
      DBNAME: itop
      DBHOST: db
      DBADMINUSER: root
      DBADMINPASSWORD: "___rootpw___"
      ITOPURL: https://itop.some.where/
    volumes:
      - data:/var/www/html/data
      - conf:/var/www/html/conf
      - production:/var/www/html/env-production
    ports:
      - 800:80

networks:
  default:

volumes:
  db:
  conf:
  data:
  production:
```

## Configuration
You can change these environment variables:

```
# Version to download
ENV ITOP_VERSION=3.2.1
ENV ITOP_SUBVERSION=1
ENV ITOP_REVISION=16749

# DB options
ENV DBHOST=db
ENV DBUSER=itop
ENV DBPASSWORD=itop
ENV DBNAME=itop

# Default user, password and language
ENV ITOPADMIN=admin
ENV ITOPPASSWORD=admin
ENV ITOPLANG="EN US"

# Default URL. This must match your browser URL!
ENV ITOPURL=http://itop/
ENV DBADMIN=root

# We need this to auto configure database for iTop
ENV DBADMINPASSWORD=admin

# By default, we will install instance. But it is autodetected. If iTop is
# already installed, this will be ignored.
ENV ITOPMODE=install

# Where to download IPAM module
ENV TEEMIP_URL="https://sourceforge.net/projects/teemip/files/teemip%20-%20an%20iTop%20module/3.2.1/teemip-core-ip-mgmt-3.2.1-813.zip/download"
```

## How it works
When docker image is started, it does check if directories are mounted to
persistent volumes. If so, default data are copied to persistent volumes.

Directories for permanent storage:
- conf
- data
- extensions
- env-production

If iTop is not installed yet (/var/www/html/conf/installed.stamp does not exists),
setup is run. If setup fails, it try to run upgrade. If setup or upgrade is
OK, /var/www/html/conf/installed.stamp is created.
Next, file permissions are restored to www-data user on /var/www/html

If iTop is already installed, it just runs apache.
