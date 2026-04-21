# PostgreSQL HA Lab with Monitoring and Automation

A hands-on Oracle Linux 9 lab project showing PostgreSQL streaming replication, monitoring with Prometheus and Grafana, and deployment automation with Bash scripts.

## Overview

This project includes:

- PostgreSQL primary instance on port 5432
- PostgreSQL replica instance on port 5433
- Streaming replication
- Monitoring stack with:
  - Node Exporter
  - postgres_exporter
  - Prometheus
  - Grafana
- Bash automation scripts to recreate the setup on a fresh VM

## Project Structure

```text
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
