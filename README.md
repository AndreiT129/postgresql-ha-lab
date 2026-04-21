# PostgreSQL HA Lab with Monitoring and Automation

This project demonstrates a PostgreSQL lab environment built on Oracle Linux 9, including streaming replication, monitoring, and automation.

## Features

- PostgreSQL primary instance (port 5432)
- PostgreSQL replica instance (port 5433)
- Streaming replication
- Monitoring stack:
  - Node Exporter
  - postgres_exporter (2 instances)
  - Prometheus
  - Grafana
- Full automation using Bash scripts

## Architecture

Primary (5432) → Replica (5433)

Metrics collected via exporters → Prometheus → Grafana dashboards

## Scripts

- `01_setup_primary.sh` — sets up PostgreSQL primary
- `02_setup_replica.sh` — creates replica using pg_basebackup
- `03_setup_monitoring.sh` — installs and configures monitoring stack

## Validation

- Replication verified using pg_stat_replication
- Replica confirmed using pg_is_in_recovery()
- Exporters returning pg_up = 1
- Prometheus targets all UP
- Grafana dashboards displaying metrics

## Notes

This is a lab environment for learning and demonstration purposes, not production-ready.
