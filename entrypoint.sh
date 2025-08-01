#!/bin/bash

set -e

echo "Preparing directories..."
mkdir -p /home/itop/extensions /home/itop/conf /home/itop/data /home/itop/env-production
chown -R www-data /home/itop

echo "Waiting for database..."
until mysqladmin ping -h "$DBHOST" -P "$DBPORT" -u"$DBUSER" -p"$DBPASSWORD" --silent; do
    echo -n "."
    sleep 5
done
echo "Database ready" 

mysql -h "$DBHOST" -P "$DBPORT" -u"$DBADMINUSER" -p"$DBADMINPASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS \`$DBNAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '$DBUSER'@'%' IDENTIFIED BY '$DBPASSWORD';
GRANT ALL PRIVILEGES ON \`$DBNAME\`.* TO '$DBUSER'@'%';
FLUSH PRIVILEGES;
EOF
echo "✅ Database '$DBNAME' and user '$DBUSER' are ready."

if [ -f /home/itop/installed.stamp ]; then
  echo "Skipping setup - already set"
else 
  echo "Running setup"
  envsubst </home/itop/preinstall-clean.xml >/home/itop/preinstall.xml
  cd /var/www/html/setup/unattended-install
  if bash ./install-itop.sh /home/itop/preinstall.xml; then
    rm /home/itop/preinstall.xml
    touch /home/itop/installed.stamp
    echo "Setup finished OK!"
  else
    ITOPMODE=update
    envsubst </home/itop/preinstall-clean.xml >/home/itop/preinstall.xml
    if bash ./install-itop.sh /home/itop/preinstall.xml; then
      rm /home/itop/preinstall.xml
      touch /home/itop/installed.stamp
      echo "Update finished OK!"
    else
      echo "Setup or update failed. Exiting"
      exit 1
    fi
  fi
fi

for d in extensions conf data env-production; do
  mv /var/www/html/$d /home/itop/
  ln -sf /home/itop/$d /var/www/html/$d
done
chown -R www-data /home/itop

echo "Running application"
apache2-foreground

