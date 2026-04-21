#!/bin/bash
set -e

PRIMARY_SUBNET="192.168.99.0/24"
REPL_USER="replicator"
REPL_PASS="replica123"
MONITOR_USER="monitor"
MONITOR_PASS="monitor123"

echo "[1/7] Installing PostgreSQL..."
dnf install -y postgresql-server postgresql-contrib

echo "[2/7] Initializing PostgreSQL primary cluster..."
postgresql-setup --initdb

echo "[3/7] Configuring postgresql.conf..."
sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf

grep -q "^wal_level = replica" /var/lib/pgsql/data/postgresql.conf || echo "wal_level = replica" >> /var/lib/pgsql/data/postgresql.conf
grep -q "^max_wal_senders = 5" /var/lib/pgsql/data/postgresql.conf || echo "max_wal_senders = 5" >> /var/lib/pgsql/data/postgresql.conf
grep -q "^wal_keep_size = 128MB" /var/lib/pgsql/data/postgresql.conf || echo "wal_keep_size = 128MB" >> /var/lib/pgsql/data/postgresql.conf

echo "[4/7] Configuring pg_hba.conf..."

# Replace localhost TCP auth from ident to md5 if present
sed -i 's/^host[[:space:]]\+all[[:space:]]\+all[[:space:]]\+127\.0\.0\.1\/32[[:space:]]\+ident/host    all             all             127.0.0.1\/32            md5/' /var/lib/pgsql/data/pg_hba.conf
sed -i 's/^host[[:space:]]\+replication[[:space:]]\+all[[:space:]]\+127\.0\.0\.1\/32[[:space:]]\+ident/host    replication     all             127.0.0.1\/32            md5/' /var/lib/pgsql/data/pg_hba.conf

# Replace local socket auth to keep admin easy in lab
sed -i 's/^local[[:space:]]\+all[[:space:]]\+all[[:space:]]\+.*/local   all             all                                     peer/' /var/lib/pgsql/data/pg_hba.conf
sed -i 's/^local[[:space:]]\+replication[[:space:]]\+all[[:space:]]\+.*/local   replication     all                                     peer/' /var/lib/pgsql/data/pg_hba.conf

# Add lab subnet rules if missing
grep -q "host all all ${PRIMARY_SUBNET} md5" /var/lib/pgsql/data/pg_hba.conf || \
echo "host    all             all             ${PRIMARY_SUBNET}            md5" >> /var/lib/pgsql/data/pg_hba.conf

grep -q "host replication ${REPL_USER} ${PRIMARY_SUBNET} md5" /var/lib/pgsql/data/pg_hba.conf || \
echo "host    replication     ${REPL_USER}     ${PRIMARY_SUBNET}            md5" >> /var/lib/pgsql/data/pg_hba.conf

# Add localhost rules if missing
grep -q "host all ${MONITOR_USER} 127.0.0.1/32 md5" /var/lib/pgsql/data/pg_hba.conf || \
echo "host    all             ${MONITOR_USER}  127.0.0.1/32               md5" >> /var/lib/pgsql/data/pg_hba.conf

grep -q "host replication ${REPL_USER} 127.0.0.1/32 md5" /var/lib/pgsql/data/pg_hba.conf || \
echo "host    replication     ${REPL_USER}     127.0.0.1/32               md5" >> /var/lib/pgsql/data/pg_hba.conf

grep -q "host all all 127.0.0.1/32 md5" /var/lib/pgsql/data/pg_hba.conf || \
echo "host    all             all             127.0.0.1/32               md5" >> /var/lib/pgsql/data/pg_hba.conf

echo "[5/7] Enabling and starting PostgreSQL..."
systemctl enable --now postgresql

echo "[6/7] Creating replication and monitor roles..."
su - postgres -c "psql -tc \"SELECT 1 FROM pg_roles WHERE rolname='${REPL_USER}'\" | grep -q 1 || psql -c \"CREATE ROLE ${REPL_USER} WITH REPLICATION LOGIN PASSWORD '${REPL_PASS}';\""
su - postgres -c "psql -tc \"SELECT 1 FROM pg_roles WHERE rolname='${MONITOR_USER}'\" | grep -q 1 || psql -c \"CREATE ROLE ${MONITOR_USER} WITH LOGIN PASSWORD '${MONITOR_PASS}';\""
su - postgres -c "psql -c \"GRANT pg_monitor TO ${MONITOR_USER};\""

echo "[7/7] Reloading PostgreSQL and opening firewall..."
su - postgres -c "psql -c 'SELECT pg_reload_conf();'"
firewall-cmd --add-service=postgresql --permanent
firewall-cmd --reload

echo "Primary setup completed."