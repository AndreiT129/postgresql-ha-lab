# PostgreSQL HA Lab with Monitoring and Automation

A hands-on Oracle Linux 9 lab project showing PostgreSQL streaming replication, monitoring with Prometheus and Grafana, and deployment automation with Bash scripts.

---

## Overview

This project includes:

- PostgreSQL primary instance on port 5432  
- PostgreSQL replica instance on port 5433  
- Streaming replication  
- Monitoring stack:
  - Node Exporter  
  - postgres_exporter  
  - Prometheus  
  - Grafana  
- Bash automation scripts to recreate the setup on a fresh VM  

---

## Architecture

Primary (5432) → Replica (5433)  
Exporters → Prometheus → Grafana  

---

## Project Structure

```
postgresql-ha-lab/
├── README.md
├── scripts/
│   ├── 01_setup_primary.sh
│   ├── 02_setup_replica.sh
│   └── 03_setup_monitoring.sh
└── docs/
    ├── architecture.md
    ├── verification.md
    └── screenshots/
```

---

## Automation Scripts

- `01_setup_primary.sh` — installs and configures the PostgreSQL primary  
- `02_setup_replica.sh` — creates the replica using `pg_basebackup`  
- `03_setup_monitoring.sh` — installs Prometheus, Grafana, and exporters  

---

## Validation

The project was validated on a fresh Oracle Linux 9 VM by confirming:

- primary and replica setup completed successfully  
- replication worked correctly  
- exporters returned healthy metrics  
- Prometheus targets were UP  
- Grafana dashboards displayed PostgreSQL and system metrics  

---

## Key Skills Demonstrated

- PostgreSQL installation and configuration  
- Streaming replication  
- Monitoring with Prometheus and Grafana  
- Linux service management with systemd  
- Network and firewall configuration  
- Bash automation  
- End-to-end validation on a clean VM  

---

## Notes

This is a lab environment built for learning and portfolio purposes, not a production deployment.
