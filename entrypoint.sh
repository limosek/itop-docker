#!/bin/sh

echo "Preparing directories..."
mkdir -p /home/itop/extensions /home/itop/conf /home/itop/data /home/itop/env-production

if [ -l /var/www/html/data ]; then
  echo "Skipping setup - already set"
else 
  echo "Running setup"
  envsubst </home/itop/preinstall-clean.xml >/home/itop/preinstall.xml
  for d in extensions conf data env-production; do
    mv /var/www/html/$d /home/itop/
    ln -sf /home/itop/$d /var/www/html/$d
  done
  bash /var/www/html/setup/unattended-install/install-itop.sh /tmp/preinstall.xml
fi

echo "Running application"
apache2-foreground

