# Architecture

## Overview

This lab runs two PostgreSQL instances on the same Oracle Linux 9 VM:

- Primary instance on port 5432  
- Replica instance on port 5433  

Streaming replication is configured between the two instances.

---

## Monitoring Stack

The monitoring stack includes:

- Node Exporter  
- postgres_exporter (primary - port 9187)  
- postgres_exporter (replica - port 9188)  
- Prometheus  
- Grafana  

---

## Data Flow

PostgreSQL → Exporters → Prometheus → Grafana  

---

## Network Setup

The VM uses two networks:

- Public network (internet access)  
- Lab network (internal PostgreSQL communication)  

This allows package installation while keeping the lab isolated.
