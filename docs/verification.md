# Verification

## Replication Checks

On primary:

```sql
SELECT client_addr, state FROM pg_stat_replication;
```

Expected:
- A row is returned
- state = streaming

On replica:

```sql
SELECT pg_is_in_recovery();
```

Expected:
- Returns: true

---

## Data Replication Test

On primary:

```bash
psql -p 5432 -c "CREATE TABLE test_rep (id INT);"
psql -p 5432 -c "INSERT INTO test_rep VALUES (1);"
```

On replica:

```bash
psql -p 5433 -c "SELECT * FROM test_rep;"
```

Expected:
- Data is visible on replica

---

## Exporter Checks

```bash
curl -s http://127.0.0.1:9100/metrics | head
curl -s http://127.0.0.1:9187/metrics | grep pg_up
curl -s http://127.0.0.1:9188/metrics | grep pg_up
```

Expected:
- pg_up = 1 for both instances

---

## Prometheus Check

```bash
curl -s http://127.0.0.1:9090/-/healthy
```

Expected:
- Prometheus is Healthy

---

## Grafana Check

- Grafana accessible on port 3000
- Prometheus added as data source
- Dashboards imported successfully
- Metrics visible in dashboards
