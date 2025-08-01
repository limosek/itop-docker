FROM php:8.1-apache

# Instalace závislostí
RUN apt-get update && apt-get install -y \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    git \
    curl \
    mariadb-client \
    gettext-base \
    libzip-dev \
    && docker-php-ext-install pdo pdo_mysql gd mbstring xml mysqli soap zip

# Nastavení dokument rootu
ENV ITOP_VERSION=3.2.1-1
ENV ITOP_REVISION=16749
ENV DBHOST=db
ENV DBUSER=itop
ENV DBPASSWORD=itop
ENV DBNAME=itop
ENV ITOPADMIN=admin
ENV ITOPPASSWORD=admin
ENV ITOPLANG="EN US"

WORKDIR /var/www/html

VOLUME /var/www/html/data
VOLUME /var/www/html/conf
VOLUME /var/www/html/extensions/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh

# Stáhneme iTop z GitHubu
RUN curl -sL https://sourceforge.net/projects/itop/files/itop/${ITOP_VERSION}/iTop-${ITOP_VERSION}-${ITOP_REVISION}.zip/download \
    -o itop.zip && \
    unzip itop.zip && \
    rm itop.zip && \
    mv web/* . && \
    rm -rf web

# Aktivace Apache mod_rewrite
RUN a2enmod rewrite

# Apache config pro iTop
COPY apache-itop.conf /etc/apache2/sites-available/000-default.conf

COPY preinstall.xml /tmp/preinstall-clean.xml
RUN envsubst </tmp/preinstall-clean.xml >/tmp/preinstall.xml 
#COPY ./unattended_install.php /var/www/html/toolkit/
RUN cd datamodels && ln -s 2.x latest
RUN  bash setup/unattended-install/install-itop.sh /tmp/preinstall.xml
#cd toolkit && php unattended_install.php --response_file=/tmp/preinstall.xml

# Oprávnění
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

