#!/bin/bash

SECRET_KEY=$(/home/netbox/netbox/netbox/generate_secret_key.py)
sed -i "s#secret-key#${SECRET_KEY}#" \
  /home/netbox/netbox/netbox/netbox/configuration.py

if mdata-get netbox_db_password 1>/dev/null 2>&1; then
  DB_PWD=`mdata-get netbox_db_password`
  sed -i "s#netbox-db-password#${DB_PWD}#" \
    /home/netbox/netbox/netbox/netbox/configuration.py
  # setup database
  sudo -u postgres psql -c "CREATE DATABASE netbox;"
  sudo -u postgres psql -c "CREATE USER netbox WITH PASSWORD '${DB_PWD}';"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;"
fi

HOSTNAME=$(/usr/bin/hostname)
sed -i "s#netbox.example.com#${HOSTNAME}#" \
  /home/netbox/netbox/netbox/netbox/configuration.py

# migrate db
if mdata-get netbox_admin_email 1>/dev/null 2>&1; then
  ADMIN_EMAIL=$(mdata-get netbox_admin_email)
else
  ADMIN_EMAIL="info@example.com"
fi
cd /home/netbox/netbox/netbox
python3.6 manage.py migrate || true
python3.6 manage.py createsuperuser --username "admin" --no-input --email "${ADMIN_EMAIL}" || true
python3.6 manage.py collectstatic --no-input || true

# start services
svccfg import /opt/local/lib/svc/manifest/netbox.xml
svccfg import /opt/local/lib/svc/manifest/netbox-rs.xml
