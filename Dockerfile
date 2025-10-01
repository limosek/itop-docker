FROM debian:trixie

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
    patch
 
RUN apt-get install -y \
    php-pdo php-mysql php-gd php-mbstring php-xml php-mysqli php-soap php-zip php-ldap php-cli apache2 libapache2-mod-php

RUN apt-get install -y curl unzip

RUN a2enmod php8.4

ARG ITOP_VERSION=3.2.2
ARG ITOP_SUBVERSION=1
ARG ITOP_REVISION=17851

# Nastavení dokument rootu
ENV ITOP_VERSION=${ITOP_VERSION}
ENV ITOP_SUBVERSION=${ITOP_SUBVERSION}
ENV ITOP_REVISION=${ITOP_REVISION}
ENV DBHOST=db
ENV DBUSER=itop
ENV DBPASSWORD=itop
ENV DBPORT=3306
ENV DBNAME=itop
ENV DBTLS=off
ENV ITOPADMIN=admin
ENV ITOPPASSWORD=admin
ENV ITOPLANG="EN US"
ENV ITOPURL=http://itop/
ENV DBADMINUSER=root
ENV DBADMINPASSWORD=""
ENV ITOPMODE=install
ENV TESTONLY=""

# Aktivace Apache mod_rewrite
RUN a2enmod rewrite

RUN chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html
VOLUME /home/itop
USER www-data

ENTRYPOINT /entrypoint.sh

# Stáhneme iTop z GitHubu
RUN pwd; ls -la
RUN curl -vL https://sourceforge.net/projects/itop/files/itop/${ITOP_VERSION}-${ITOP_SUBVERSION}/iTop-${ITOP_VERSION}-${ITOP_SUBVERSION}-${ITOP_REVISION}.zip/download -o itop.zip
RUN unzip itop.zip
RUN rm itop.zip
RUN mv web/* .
RUN rm -rf web

COPY extensions/ /var/www/html/extensions
RUN if ls extensions/*zip; then \
      for i in extensions/*zip; do \
        (cd extensions && unzip $(basename $i) && rm $(basename $i)); \
      done; \
    fi

USER root

# Copy files out of HTML tree for backup
RUN cp -R /var/www/html /home/itop/

# Apply patches
COPY patches/*patch /tmp
RUN cd /var/www/html; for p in /tmp/*.patch; do patch -p0 <$p; done

# Apache config pro iTop
COPY apache-itop.conf /etc/apache2/sites-available/000-default.conf

COPY entrypoint.sh /

COPY preinstall.xml /home/itop/preinstall-clean.xml
RUN chmod +x /entrypoint.sh



