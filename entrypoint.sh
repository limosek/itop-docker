#!/bin/bash

set -e

set_perms() {
  echo "Syncing file permissions $1"
  chown -R www-data:www-data "$1"
}

prepare_dirs() {
  echo "Preparing directories..."
  for d in conf data extensions env-production; do
    mkdir -p /var/www/html/$d
    if ! [ -f /var/www/html/$d/.htaccess ]; then
      cp -R /home/itop/$d/.* /var/www/html/$d/ || true
      set_perms /var/www/html/$d
    fi
  done
}

update_dirs() {
  echo "Updating directories..."
  for d in conf data extensions env-production; do
    set_perms /var/www/html/$d/
  done
}

if [ "$TESTONLY" = "sh" ]; then
  bash -i
fi

echo "Waiting for database server...  --ssl=$DBTLS -h$DBHOST -P$DBPORT -u$DBUSER"
until mariadb-admin ping --ssl=$DBTLS -h "$DBHOST" -P "$DBPORT" -u"$DBUSER" -p"$DBPASSWORD" --silent; do
    echo -n "."
    sleep 5
done
echo "Database server ready" 

if [ -n "$DBADMINPASSWORD" ]; then
  mariadb --ssl=$DBTLS -h "$DBHOST" -P "$DBPORT" -u"$DBADMINUSER" -p"$DBADMINPASSWORD" <<EOF
  CREATE DATABASE IF NOT EXISTS \`$DBNAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

  CREATE USER IF NOT EXISTS '$DBUSER'@'%' IDENTIFIED BY '$DBPASSWORD';
  GRANT ALL PRIVILEGES ON \`$DBNAME\`.* TO '$DBUSER'@'%';
  FLUSH PRIVILEGES;
EOF
  echo "Database '$DBNAME' and user '$DBUSER' crearted."
else
  echo "No DB admin permissions - assuming that USER and DB already exists."
fi

if [ -f /var/www/html/conf/installed.stamp ]; then
  echo "Skipping setup - already set"
else 
  echo "Running setup"
  prepare_dirs
  envsubst </home/itop/preinstall-clean.xml >/home/itop/preinstall.xml
  cd /var/www/html/setup/unattended-install
  if bash ./install-itop.sh /home/itop/preinstall.xml; then
    rm /home/itop/preinstall.xml
    touch /var/www/html/conf/installed.stamp
    update_dirs
    echo "Setup finished OK!"
  else
    ITOPMODE=upgrade
    envsubst </home/itop/preinstall-clean.xml >/home/itop/preinstall.xml
    if bash ./install-itop.sh /home/itop/preinstall.xml; then
      rm /home/itop/preinstall.xml
      touch /var/www/html/conf/installed.stamp
      update_dirs
      echo "Update finished OK!"
    else
      echo "Setup or update failed. Exiting"
      exit 1
    fi
  fi
fi

if [ "$TESTONLY" = "true" ]; then
  BADFILEs=$(find /var/www/html/ -type f -a '!' -user www-data)
  echo $BADFILES
  if [ -z "$BADFILES" ]; then
    echo =====TEST_OK
    exit
  fi
elif [ "$TESTONLY" = "sh" ]; then
  bash -i
fi

echo "Running application"
#apache2-foreground
apache2ctl -X

