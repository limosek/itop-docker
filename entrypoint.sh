#!/bin/sh

chown -R www-data /var/www/html/extensions
chown -R www-data /var/www/html/conf
chown -R www-data /var/www/html/data

envsubst </tmp/preinstall-clean.xml >/tmp/preinstall.xml
/var/www/html/setup/unattended-install/install-itop.sh /tmp/preinstall.xml
apache2-foreground
