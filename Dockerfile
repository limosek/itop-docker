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
    libldap-dev \
    graphviz \
    && docker-php-ext-install pdo pdo_mysql gd mbstring xml mysqli soap zip ldap

# Nastavení dokument rootu
ENV ITOP_VERSION=3.2.1
ENV ITOP_SUBVERSION=1
ENV ITOP_REVISION=16749
ENV DBHOST=db
ENV DBUSER=itop
ENV DBPASSWORD=itop
ENV DBNAME=itop
ENV ITOPADMIN=admin
ENV ITOPPASSWORD=admin
ENV ITOPLANG="EN US"
ENV ITOPURL=http://itop/
ENV DBADMINUSER=root
ENV DBADMINPASSWORD=""
ENV ITOPMODE=install

# Aktivace Apache mod_rewrite
RUN a2enmod rewrite

WORKDIR /var/www/html
VOLUME /home/itop
USER www-data

ENTRYPOINT /entrypoint.sh

# Stáhneme iTop z GitHubu
RUN curl -sL https://sourceforge.net/projects/itop/files/itop/${ITOP_VERSION}-${ITOP_SUBVERSION}/iTop-${ITOP_VERSION}-${ITOP_SUBVERSION}-${ITOP_REVISION}.zip/download \
    -o itop.zip && \
    unzip itop.zip && \
    rm itop.zip && \
    mv web/* . && \
    rm -rf web

COPY extensions/ /var/www/html/extensions
RUN if ls extensions/*zip; then \
      for i in extensions/*zip; do \
        (cd extensions && unzip $(basename $i) && rm $(basename $i)); \
      done; \
    fi

USER root

# Copy files out of HTML tree for backup
RUN cp -R /var/www/html /home/itop/

# Apache config pro iTop
COPY apache-itop.conf /etc/apache2/sites-available/000-default.conf

COPY entrypoint.sh /

COPY preinstall.xml /home/itop/preinstall-clean.xml
RUN chmod +x /entrypoint.sh



