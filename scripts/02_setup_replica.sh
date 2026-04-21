#!/bin/bash
set -e

PRIMARY_HOST="127.0.0.1"
REPL_USER="replicator"
REPL_PASS="replica123"
REPLICA_DATA="/var/lib/pgsql/data2"
REPLICA_PORT="5433"

echo "[1/6] Stopping old replica instance if running..."
su - postgres -c "pg_ctl -D ${REPLICA_DATA} stop" || true

echo "[2/6] Cleaning replica directory..."
rm -rf "${REPLICA_DATA}"
mkdir -p "${REPLICA_DATA}"
chown postgres:postgres "${REPLICA_DATA}"
chmod 700 "${REPLICA_DATA}"

echo "[3/6] Running pg_basebackup from primary..."
su - postgres -c "PGPASSWORD='${REPL_PASS}' pg_basebackup -h ${PRIMARY_HOST} -D ${REPLICA_DATA} -U ${REPL_USER} -P -R"

echo "[4/6] Configuring replica port..."
if grep -q "^#port = 5432" ${REPLICA_DATA}/postgresql.conf; then
  sed -i "s/^#port = 5432/port = ${REPLICA_PORT}/" ${REPLICA_DATA}/postgresql.conf
elif grep -q "^port = 5432" ${REPLICA_DATA}/postgresql.conf; then
  sed -i "s/^port = 5432/port = ${REPLICA_PORT}/" ${REPLICA_DATA}/postgresql.conf
elif ! grep -q "^port = ${REPLICA_PORT}" ${REPLICA_DATA}/postgresql.conf; then
  echo "port = ${REPLICA_PORT}" >> ${REPLICA_DATA}/postgresql.conf
fi

if grep -q "^#listen_addresses = 'localhost'" ${REPLICA_DATA}/postgresql.conf; then
  sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" ${REPLICA_DATA}/postgresql.conf
elif ! grep -q "^listen_addresses = '\*'" ${REPLICA_DATA}/postgresql.conf; then
  echo "listen_addresses = '*'" >> ${REPLICA_DATA}/postgresql.conf
fi

echo "[5/6] Adjusting pg_hba.conf for monitor access..."
sed -i 's/^host[[:space:]]\+all[[:space:]]\+all[[:space:]]\+127\.0\.0\.1\/32[[:space:]]\+ident/host    all             all             127.0.0.1\/32            md5/' ${REPLICA_DATA}/pg_hba.conf || true
sed -i 's/^host[[:space:]]\+replication[[:space:]]\+all[[:space:]]\+127\.0\.0\.1\/32[[:space:]]\+ident/host    replication     all             127.0.0.1\/32            md5/' ${REPLICA_DATA}/pg_hba.conf || true
sed -i 's/^local[[:space:]]\+all[[:space:]]\+all[[:space:]]\+.*/local   all             all                                     peer/' ${REPLICA_DATA}/pg_hba.conf || true

grep -q "host all monitor 127.0.0.1/32 md5" ${REPLICA_DATA}/pg_hba.conf || \
echo "host    all             monitor         127.0.0.1/32               md5" >> ${REPLICA_DATA}/pg_hba.conf

grep -q "host all all 127.0.0.1/32 md5" ${REPLICA_DATA}/pg_hba.conf || \
echo "host    all             all             127.0.0.1/32               md5" >> ${REPLICA_DATA}/pg_hba.conf

echo "[6/6] Starting replica..."
su - postgres -c "pg_ctl -D ${REPLICA_DATA} -l ${REPLICA_DATA}/logfile start"

firewall-cmd --add-port=${REPLICA_PORT}/tcp --permanent
firewall-cmd --reload

echo "Replica setup completed."