#!/bin/bash

set -e

echo "Preparing directories..."
for d in conf data extensions env-production; do
  mkdir -p /var/www/html/$d
  if ! [ -f /var/www/html/$d/.htaccess ]; then
    cp -R /home/itop/$d/.* /var/www/html/$d/ || true
    chown -R www-data /var/www/html/$d
  fi
done

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
    ITOPMODE=upgrade
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
  echo "Syncing file permissions..."
  chown -R www-data /var/www/html
fi

echo "Running application"
apache2-foreground

