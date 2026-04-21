#!/bin/bash
set -e

NODE_EXPORTER_VERSION="1.11.1"
POSTGRES_EXPORTER_VERSION="0.15.0"
PROMETHEUS_VERSION="3.3.0"

MONITOR_USER="monitor"
MONITOR_PASS="monitor123"

echo "[1/10] Installing basic tools..."
dnf install -y wget curl tar

echo "[2/10] Installing Node Exporter..."
cd /opt
rm -rf /opt/node_exporter /opt/node_exporter.tar.gz /opt/node_exporter*.tar.gz
wget -O node_exporter.tar.gz https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzf node_exporter.tar.gz
mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64 node_exporter
id node_exporter >/dev/null 2>&1 || useradd --no-create-home --shell /sbin/nologin node_exporter
chown -R node_exporter:node_exporter /opt/node_exporter

cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/opt/node_exporter/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "[3/10] Installing postgres_exporter..."
cd /opt
rm -rf /opt/postgres_exporter /opt/postgres_exporter.tar.gz /opt/postgres_exporter*.tar.gz
wget -O postgres_exporter.tar.gz https://github.com/prometheus-community/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION}/postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzf postgres_exporter.tar.gz
mv postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-amd64 postgres_exporter
id postgres_exporter >/dev/null 2>&1 || useradd --no-create-home --shell /sbin/nologin postgres_exporter
chown -R postgres_exporter:postgres_exporter /opt/postgres_exporter

cat > /etc/postgres_exporter_5432.env <<EOF
DATA_SOURCE_NAME="host=127.0.0.1 port=5432 user=${MONITOR_USER} password=${MONITOR_PASS} dbname=postgres sslmode=disable"
EOF

cat > /etc/postgres_exporter_5433.env <<EOF
DATA_SOURCE_NAME="host=127.0.0.1 port=5433 user=${MONITOR_USER} password=${MONITOR_PASS} dbname=postgres sslmode=disable"
EOF

chown postgres_exporter:postgres_exporter /etc/postgres_exporter_5432.env /etc/postgres_exporter_5433.env
chmod 600 /etc/postgres_exporter_5432.env /etc/postgres_exporter_5433.env

cat > /etc/systemd/system/postgres_exporter_5432.service <<EOF
[Unit]
Description=Postgres Exporter (5432)
After=network.target

[Service]
User=postgres_exporter
Group=postgres_exporter
EnvironmentFile=/etc/postgres_exporter_5432.env
ExecStart=/opt/postgres_exporter/postgres_exporter --web.listen-address=:9187
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/postgres_exporter_5433.service <<EOF
[Unit]
Description=Postgres Exporter (5433)
After=network.target

[Service]
User=postgres_exporter
Group=postgres_exporter
EnvironmentFile=/etc/postgres_exporter_5433.env
ExecStart=/opt/postgres_exporter/postgres_exporter --web.listen-address=:9188
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "[4/10] Installing Prometheus..."
cd /opt
rm -rf /opt/prometheus /opt/prometheus.tar.gz /opt/prometheus*.tar.gz
wget -O prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar -xzf prometheus.tar.gz
mv prometheus-${PROMETHEUS_VERSION}.linux-amd64 prometheus

id prometheus >/dev/null 2>&1 || useradd --no-create-home --shell /sbin/nologin prometheus
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

cp /opt/prometheus/prometheus /usr/local/bin/
cp /opt/prometheus/promtool /usr/local/bin/
chmod +x /usr/local/bin/prometheus /usr/local/bin/promtool
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['127.0.0.1:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['127.0.0.1:9100']

  - job_name: 'postgres_primary_5432'
    static_configs:
      - targets: ['127.0.0.1:9187']

  - job_name: 'postgres_replica_5433'
    static_configs:
      - targets: ['127.0.0.1:9188']
EOF

cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "[5/10] Installing Grafana..."
dnf install -y https://dl.grafana.com/enterprise/release/grafana-enterprise-10.4.2-1.x86_64.rpm

echo "[6/10] Setting Grafana listen address..."
if grep -q "^;http_addr =" /etc/grafana/grafana.ini; then
  sed -i 's/^;http_addr =.*/http_addr = 0.0.0.0/' /etc/grafana/grafana.ini
elif grep -q "^http_addr =" /etc/grafana/grafana.ini; then
  sed -i 's/^http_addr =.*/http_addr = 0.0.0.0/' /etc/grafana/grafana.ini
else
  echo "http_addr = 0.0.0.0" >> /etc/grafana/grafana.ini
fi

echo "[7/10] Reloading systemd..."
systemctl daemon-reload

echo "[8/10] Starting monitoring services..."
systemctl enable --now node_exporter
systemctl enable --now postgres_exporter_5432
systemctl enable --now postgres_exporter_5433
systemctl enable --now prometheus
systemctl enable --now grafana-server

echo "[9/10] Opening firewall ports..."
firewall-cmd --add-port=3000/tcp --permanent
firewall-cmd --add-port=9090/tcp --permanent
firewall-cmd --add-port=9100/tcp --permanent
firewall-cmd --add-port=9187/tcp --permanent
firewall-cmd --add-port=9188/tcp --permanent
firewall-cmd --reload

echo "[10/10] Checking Prometheus config..."
promtool check config /etc/prometheus/prometheus.yml

echo "Monitoring setup completed."