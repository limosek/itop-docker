#!/bin/sh

echo "Preparing directories..."
mkdir -p /home/itop/extensions /home/itop/conf /home/itop/data /home/itop/env-production
chown -R www-data /home/itop

if [ -l /var/www/html/data ]; then
  echo "Skipping setup - already set"
else 
  echo "Running setup"
  envsubst </home/itop/preinstall-clean.xml >/home/itop/preinstall.xml
  
  cd /var/www/html/setup/unattended-install
  if bash ./install-itop.sh /home/itop/preinstall.xml; then
    for d in extensions conf data env-production; do
      mv /var/www/html/$d /home/itop/ || mkdir /home/itop/$d
      ln -sf /home/itop/$d /var/www/html/$d
    done
    chown -R www-data /home/itop
    rm /home/itop/preinstall.xml
    echo "Setup finished OK!"
  fi
fi

echo "Running application"
apache2-foreground

