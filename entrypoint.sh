#!/bin/sh

envsubst </tmp/preinstall-clean.xml >/tmp/preinstall.xml
/var/www/setup/unattended-install/install-itop.sh /tmp/preinstall.xml
apache2-foreground
