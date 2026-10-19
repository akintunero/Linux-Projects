# Step 7: System Monitoring

> **Time:** ~8-10 hours · **Level:** Beginner → Advanced
> **Prerequisites:** [Step 3](step-03-networking-basics.md), [Step 4](step-04-shell-scripting.md) · **Next:** [Step 8: Disk Management](step-08-disk-mgmnt.md)

<!-- -->

> [!WARNING]
> Monitoring stacks open network ports (Prometheus 9090, Grafana 3000, Loki 3100) that have **no
> authentication by default**. Do this in a throwaway VM or the devcontainer, bind services to
> `127.0.0.1` or a private network, and never expose them to the internet. Keep a second SSH session
> open while changing firewall settings.

Conventions: see [Step 1](step-01-linux-fundamentals.md#how-to-read-each-task).
The stack in Tasks 7.4 and 7.7 was run with Docker on an Ubuntu 24.04 host (Prometheus 2.55.1, node-exporter 1.8.2,
Grafana 11.3.0, Loki 3.2.1). The shell and Python scripts were run in an Ubuntu 24.04 container; `ss`
and `sar` outputs are marked *typical* where the container could not produce them. Docker is introduced in
[Step 11](step-11-virtualization-and-containers.md); here you only copy the commands.

## Which tool for which job

| Question | Tool |
|----------|------|
| What is eating CPU right now? | `top`/`htop`, `ps`, `pidstat` |
| What happened last night? | `sar` (sysstat), journald, Prometheus history |
| Is the service up from outside? | Blackbox probes, Nagios-style checks |
| Metrics over time, alerts | Prometheus + Alertmanager + Grafana |
| Logs searched centrally | Loki + Grafana (light), OpenSearch/ELK (heavy), Wazuh (security) |
| Why is one request slow? | Tracing: OpenTelemetry + Jaeger/Tempo |

---

## Beginner

### Task 7.1: Log the heaviest processes

- **What you will learn:** `ps` with sort keys (better than parsing `top` output in scripts) and append-only logging with timestamps.
- **Target distro:** both. **Risk level:** `safe`.

```bash
sudo tee /usr/local/bin/top-procs.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
# Append the top 5 CPU and memory consumers, with a timestamp, to a log file.
set -euo pipefail
log="${1:-$HOME/top-procs.log}"
{
  echo "=== $(date '+%F %T') ==="
  echo "-- top 5 by CPU --"
  ps -eo pid,user,pcpu,pmem,comm --sort=-pcpu | head -n 6
  echo "-- top 5 by memory --"
  ps -eo pid,user,pcpu,pmem,comm --sort=-pmem | head -n 6
} >> "$log"
EOF
sudo chmod +x /usr/local/bin/top-procs.sh
top-procs.sh /tmp/tp.log && head -9 /tmp/tp.log
```

**Verify it worked.** Captured (container, so few processes):

```text
=== 2026-10-17 21:45:59 ===
-- top 5 by CPU --
    PID USER     %CPU %MEM COMMAND
      1 root      0.0  0.1 bash
   3123 root      0.0  0.1 bash
   3125 root      0.0  0.2 ps
   3126 root      0.0  0.0 head
-- top 5 by memory --
    PID USER     %CPU %MEM COMMAND
```

Note `ps` `%CPU` is the average over the process lifetime. For a live view use `top -b -n 1` (or `htop` interactively). For a snapshot of system-wide load, memory, and I/O:

```bash
vmstat 1 3                      # procs, memory, swap, CPU — one line per second, 3 times
iostat -x 1 2                   # per-device utilization and wait, two samples
```

`vmstat` shows whether you are memory- or CPU-bound; `iostat` shows whether a disk is saturated (`%util` near 100, high `await`).

**Acceptance criteria**

- [ ] Each run appends a timestamped block.
- [ ] `shellcheck` is clean.
- [ ] The log is rotated (see the `logrotate` rule below).

```bash
sudo tee /etc/logrotate.d/top-procs >/dev/null <<'EOF'
/var/log/top-procs.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF
```

**Undo it:** `sudo rm /usr/local/bin/top-procs.sh /etc/logrotate.d/top-procs /tmp/tp.log`

**Troubleshooting**

- Log grows without bound: add the logrotate rule above.
- `ps: unknown sort specifier`: BusyBox `ps` differs; install `procps`.
- Numbers look low in a container: you only see your container's processes.

### Task 7.2: Log network connections every 5 minutes (`ss`, systemd timer)

- **What you will learn:** `ss` replaces the deprecated `netstat`; a systemd timer replaces cron for new jobs (logs go to the journal, missed runs can be caught up).
- **Target distro:** both. **Risk level:** `safe`. Connection logs show remote IPs (personal data): restrict the log file mode.

```bash
sudo tee /usr/local/bin/conn-log.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
# Log established TCP connections and listening sockets, one line per socket.
set -euo pipefail
log="${1:-$HOME/connections.log}"
ts="$(date '+%F %T')"
ss -Htn state established | awk -v ts="$ts" '{print ts, "ESTAB", $3, "->", $4}' >> "$log"
ss -Htln | awk -v ts="$ts" '{print ts, "LISTEN", $4}' >> "$log"
EOF
sudo chmod +x /usr/local/bin/conn-log.sh

sudo tee /etc/systemd/system/conn-log.service >/dev/null <<'EOF'
[Unit]
Description=Log network connections

[Service]
Type=oneshot
ExecStart=/usr/local/bin/conn-log.sh /var/log/connections.log
UMask=0077
EOF
sudo tee /etc/systemd/system/conn-log.timer >/dev/null <<'EOF'
[Unit]
Description=Log network connections every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now conn-log.timer
```

**Verify it worked.** *Typical output* (not run: the container had no `ss`):

```text
$ systemctl list-timers conn-log.timer
NEXT                         LEFT   LAST  PASSED  UNIT            ACTIVATES
Sat 2026-10-17 22:05:00 BST  3min   ...           conn-log.timer  conn-log.service
$ sudo tail -3 /var/log/connections.log
2026-10-17 22:00:01 LISTEN 0.0.0.0:22
2026-10-17 22:00:01 ESTAB 10.0.0.5:22 -> 10.0.0.9:51522
```

The cron equivalent is `*/5 * * * * /usr/local/bin/conn-log.sh >> ...`.

**Acceptance criteria**

- [ ] The timer is listed and fires every 5 minutes (`journalctl -u conn-log.service`).
- [ ] The log is mode `600`.
- [ ] You can explain `Persistent=true`.

**Undo it**

```bash
sudo systemctl disable --now conn-log.timer
sudo rm /etc/systemd/system/conn-log.{service,timer} /usr/local/bin/conn-log.sh /var/log/connections.log
sudo systemctl daemon-reload
```

**Troubleshooting**

- `ss: command not found`: install `iproute2`.
- Timer never fires: you enabled the `.service`, not the `.timer`.
- Empty `ESTAB` lines: no connections at that moment; that is normal.

### Task 7.3: Nagios-style uptime checks for a few services

- **What you will learn:** the plugin contract from [Task 3.8](step-03-networking-basics.md#task-38-monitor-the-network-and-write-a-custom-check) (exit 0/1/2/3), used by Nagios and Icinga. A full Nagios Core install is long and aging; **Icinga 2** is the active fork, and **Prometheus** (Task 7.4) is the modern default. This task gives you the checks plus a simple loop that alerts through the system log.
- **Target distro:** both. **Risk level:** `safe`.

```bash
P=/usr/lib/nagios/plugins          # RHEL: /usr/lib64/nagios/plugins
for check in "check_disk -w 20% -c 10% -p /" "check_load -w 5,4,3 -c 10,8,6" "check_tcp -H 127.0.0.1 -p 22"; do
  # shellcheck disable=SC2086
  out="$($P/$check 2>&1)"; rc=$?
  [[ $rc -eq 0 ]] || logger -p daemon.crit -t monitor "$out"
  echo "rc=$rc $out"
done
```

**Verify it worked.** Captured earlier (Task 3.8):

```text
DISK OK - free space: / 963166MiB (98% inode=99%);| /=16155410432B;...
LOAD OK - total load average: 0.90, 0.90, 0.48|load1=0.900;5.000;10.000;0; ...
```

Email alerts need a working MTA (`postfix` or `msmtp`) and were *not run*.

**Acceptance criteria**

- [ ] A failing check writes to the journal: `journalctl -t monitor`.
- [ ] You can name the Icinga/Nagios objects that wrap a check: host, service, contact, notification.

**Undo it:** nothing was installed beyond the plugin package.

**Troubleshooting**

- `No such file or directory` for plugins: use the RHEL path or install `monitoring-plugins-standard`.
- `$?` is wrong: capture it right after the command, as above.
- Alert storms: add a state file or let the monitoring server handle retries.

---

## Intermediate

### Task 7.4: Prometheus + Grafana dashboard

- **What you will learn:** pull-based metrics: an exporter exposes `/metrics`, Prometheus scrapes and stores them, Grafana draws them.
- **Target distro:** any host with Docker or Podman. Native packages exist too (`prometheus`, `prometheus-node-exporter`, `grafana`).
- **Risk level:** `safe` bound to localhost.

```bash
docker network create monlab
mkdir -p ~/mon && cd ~/mon
cat > prometheus.yml <<'EOF'
global:
  scrape_interval: 5s
rule_files:
  - /etc/prometheus/alerts.yml
scrape_configs:
  - job_name: node
    static_configs:
      - targets: ["node-exporter:9100"]
EOF
cat > alerts.yml <<'EOF'
groups:
  - name: host
    rules:
      - alert: HighCpu
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 85
        for: 5m
        labels: {severity: warning}
        annotations: {summary: "CPU above 85% on {{ $labels.instance }}"}
EOF
docker run -d --name node-exporter --network monlab prom/node-exporter:v1.8.2
docker run -d --name prom --network monlab -p 127.0.0.1:9090:9090 \
  -v "$PWD/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
  -v "$PWD/alerts.yml:/etc/prometheus/alerts.yml:ro" prom/prometheus:v2.55.1
docker run -d --name grafana --network monlab -p 127.0.0.1:3000:3000 grafana/grafana:11.3.0
sleep 25
curl -s 127.0.0.1:9090/api/v1/targets | python3 -c "import sys,json; d=json.load(sys.stdin); print([(t['labels']['job'],t['health']) for t in d['data']['activeTargets']])"
curl -s 127.0.0.1:3000/api/health
```

In Grafana (`http://127.0.0.1:3000`, first login `admin`/`admin`, change it) add a Prometheus data source
`http://prom:9090`, then import the community dashboard **1860** (Node Exporter Full) from the Grafana dashboards site.

**Verify it worked.** Captured:

```text
[('node', 'up')]
{
  "database": "ok",
  "version": "11.3.0",
  "commit": "d9455ff7db73b694db7d412e49a68bec767f2b5a"
}
```

The query `up` in the Prometheus UI returns value `1` (also captured). The dashboard import and the `HighCpu` rule
firing were not exercised; I did not capture `promtool check rules` output.

**Acceptance criteria**

- [ ] The `node` target is `UP` and graphs show CPU and memory.
- [ ] The alert rule loads (`Status → Rules`) and you can make it fire (`stress-ng --cpu 0 -t 10m`).
- [ ] Ports are bound to localhost, Grafana has a changed admin password.

**Undo it**

```bash
docker rm -f node-exporter prom grafana; docker network rm monlab; rm -r ~/mon
```

**Troubleshooting**

- Target `DOWN`: wrong hostname/port or containers on different networks.
- No data in Grafana: the data source URL must be reachable from the Grafana container (`http://prom:9090`, not `localhost`).
- `node-exporter` in a container reports container-ish disks; on real hosts run it as a systemd service.

### Task 7.5: Alerts: Alertmanager rules (and Zabbix as an alternative)

- **What you will learn:** alert rules with `for:` durations, severities, and routing to a receiver. The Prometheus ecosystem uses Alertmanager; **Zabbix** is the all-in-one alternative (agent + server + UI + triggers) and is worth knowing from jobs that use it.
- **Target distro:** both. **Risk level:** `safe`; a wrong receiver can spam people or leak data.

Add a disk prediction alert and test the syntax (Prometheus ships `promtool`):

```yaml
      - alert: DiskFillingUp
        expr: predict_linear(node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"}[1h], 4*3600) < 0
        for: 10m
        labels: {severity: critical}
        annotations: {summary: "Disk on {{ $labels.instance }} full within 4h"}
```

```bash
docker run --rm -v "$PWD:/w" --entrypoint promtool prom/prometheus:v2.55.1 check rules /w/alerts.yml
```

A minimal Alertmanager route (`alertmanager.yml`) that sends to a webhook:

```yaml
route:
  receiver: ops
  group_by: [alertname, instance]
receivers:
  - name: ops
    webhook_configs:
      - url: http://127.0.0.1:5001/alert
```

**Verify it worked.** *Typical output* of `promtool check rules`: `SUCCESS: 2 rules found`. Zabbix and Alertmanager
delivery were *not run*; follow the Zabbix quickstart for a server install.

**Acceptance criteria**

- [ ] `promtool` accepts the rules file.
- [ ] A forced alert reaches the receiver.
- [ ] Every alert has a severity and a human-readable summary; you can say what action it asks for.

**Undo it:** remove the rule from `alerts.yml` and reload (`docker kill -s HUP prom`).

**Troubleshooting**

- Alert stays `pending`: `for:` has not elapsed.
- No notification: the receiver is unreachable or the route does not match the labels.
- Too many alerts: alert on symptoms (latency, errors, disk full soon), not every CPU spike.

### Task 7.6: Daily performance reports with `sar`

- **What you will learn:** `sysstat` records CPU, memory, disk and network history every 10 minutes, so you can answer "what happened at 03:00?".
- **Target distro:** both (`sudo apt install -y sysstat`, then set `ENABLED="true"` in `/etc/default/sysstat` and `sudo systemctl enable --now sysstat`; RHEL: `sudo dnf install -y sysstat && sudo systemctl enable --now sysstat`). **Risk level:** `safe`.

```bash
sar -u 1 3                  # live CPU
sar -r 1 3                  # live memory
sar -u -f /var/log/sysstat/sa$(date +%d)     # today's history (RHEL: /var/log/sa/saDD)
```

A report script (mails if `mail` exists, else prints):

```bash
sudo tee /usr/local/bin/sar-report.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
# Daily sysstat summary. Usage: sar-report.sh [recipient]
set -euo pipefail
to="${1:-}"
dir=/var/log/sysstat; [[ -d $dir ]] || dir=/var/log/sa
file="$dir/sa$(date -d yesterday +%d)"
[[ -r "$file" ]] || { echo "no sysstat file: $file" >&2; exit 1; }
report="$({
  echo "== Daily report for $(hostname), $(date -d yesterday +%F) =="
  sar -u -f "$file" | tail -n 2
  sar -r -f "$file" | tail -n 2
  sar -d -f "$file" | tail -n 4
})"
if [[ -n "$to" ]] && command -v mail >/dev/null; then mail -s "sar report $(hostname)" "$to" <<< "$report"; else echo "$report"; fi
EOF
sudo chmod +x /usr/local/bin/sar-report.sh
```

**Verify it worked.** *Typical output* of `sar -u 1 3` (not captured; container sar had no data):

```text
Linux 6.8.0 (host)  10/17/2026  _x86_64_  (4 CPU)
10:00:01  CPU  %user  %nice  %system  %iowait  %steal  %idle
10:00:02  all   2.01   0.00     0.50     0.00    0.00  97.49
...
Average:  all   1.80   0.00     0.45     0.02    0.00  97.73
```

**Acceptance criteria**

- [ ] `/var/log/sysstat/` gets a new file each day.
- [ ] The report script runs from cron or a timer and shows yesterday's averages.
- [ ] You can spot an I/O wait problem (`%iowait` high) in the data.

**Undo it:** `sudo rm /usr/local/bin/sar-report.sh; sudo systemctl disable --now sysstat`

**Troubleshooting**

- `Cannot open /var/log/sysstat/saNN`: sysstat is not enabled, or it is a new install with no history yet.
- Debian: collection is off until `ENABLED="true"`.
- `mail: command not found`: install `bsd-mailx` plus an MTA, or send through your monitoring system instead.

---

## Advanced

### Task 7.7: Central logs with Loki + Grafana (and ELK/OpenSearch)

- **What you will learn:** index only labels, store log lines cheaply, query with LogQL. Loki + Grafana is much lighter than Elasticsearch/Kibana; ELK/OpenSearch is better for full-text analytics. Agents: **Grafana Alloy** (current) or Promtail (legacy) ship files and the journal.
- **Target distro:** both. **Risk level:** `safe` on localhost; logs often contain secrets and personal data, so restrict access.

Run Loki (from Task 7.4's network) and push a test line through its HTTP API, then query it:

```bash
docker run -d --name loki --network monlab -p 127.0.0.1:3100:3100 grafana/loki:3.2.1
sleep 20; curl -s 127.0.0.1:3100/ready
ts=$(date +%s%N)
curl -s -o /dev/null -w "push http=%{http_code}\n" -H 'Content-Type: application/json' \
  -X POST 127.0.0.1:3100/loki/api/v1/push \
  --data "{\"streams\":[{\"stream\":{\"job\":\"lab\",\"host\":\"web1\"},\"values\":[[\"$ts\",\"sshd: Failed password for root from 203.0.113.5\"]]}]}"
sleep 2
curl -s -G 127.0.0.1:3100/loki/api/v1/query_range --data-urlencode 'query={job="lab"} |= "Failed password"'
```

In Grafana add a Loki data source (`http://loki:3100`) and use Explore with `{job="lab"} |= "Failed password"`.
Count failures per host with `sum by (host) (count_over_time({job="lab"} |= "Failed password" [5m]))`.

**Verify it worked.** Captured:

```text
Ingester not ready: waiting for 15s after being ready      <- first /ready call, wait and retry
push http=204
success sshd: Failed password for root from 203.0.113.5     <- parsed from the query result
```

An agent (Alloy/Promtail) reading `/var/log/auth.log` or the journal was *not* set up. Starting point:
[Grafana Alloy docs](https://grafana.com/docs/alloy/latest/).

**Acceptance criteria**

- [ ] A line pushed (or shipped) from a host is found by a LogQL query.
- [ ] You alert on a log pattern (Grafana alert rule on the query above).
- [ ] Retention and disk limits are set (`limits_config.retention_period`).

**Undo it:** `docker rm -f loki`

**Troubleshooting**

- `push http=400`: timestamp too old/new or out of order for the stream.
- `Ingester not ready`: wait 15 s after start.
- High cardinality labels (user IDs, IPs as labels) make Loki slow; keep labels few and static.

### Task 7.8: Distributed tracing with OpenTelemetry and Jaeger

- **What you will learn:** a trace follows one request across services as spans. Instrument apps with OpenTelemetry SDKs, send to a collector, view in Jaeger or Grafana Tempo.
- **Target distro:** any with Docker. **Risk level:** `safe`. *I did not run this task*: command output below is *typical*.

```bash
docker run -d --name jaeger -p 127.0.0.1:16686:16686 -p 127.0.0.1:4317:4317 -p 127.0.0.1:4318:4318 \
  jaegertracing/all-in-one:1.62.0
python3 -m venv ~/otel && . ~/otel/bin/activate
pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
cat > trace_demo.py <<'EOF'
import time
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

provider = TracerProvider(resource=Resource.create({"service.name": "demo-api"}))
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint="http://127.0.0.1:4318/v1/traces")))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer("demo")

with tracer.start_as_current_span("handle-request"):
    with tracer.start_as_current_span("db-query"):
        time.sleep(0.2)
    with tracer.start_as_current_span("render"):
        time.sleep(0.05)
provider.shutdown()
EOF
python3 trace_demo.py
```

Open `http://127.0.0.1:16686`, pick service `demo-api`: one trace with `handle-request` containing `db-query` (about 200 ms) and `render`.

**Verify it worked.** Ask Jaeger's API for the service and the trace (captured in a container):

```bash
curl -s "http://127.0.0.1:16686/api/services"
curl -s "http://127.0.0.1:16686/api/traces?service=demo-api&limit=1" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); [print(s["operationName"], round(s["duration"]/1000), "ms") for t in d["data"] for s in t["spans"]]'
```

*Captured output:*

```text
{"data":["demo-api"],"total":1,"limit":0,"offset":0,"errors":null}
db-query 200 ms
render 50 ms
handle-request 251 ms
```

Three spans share one trace ID, `handle-request` is the parent, and `db-query` is the slowest child.

**Acceptance criteria**

- [ ] A trace with three spans appears and the slowest span is obvious.
- [ ] You can name what a sampling policy is and why production does not trace 100%.

**Undo it:** `docker rm -f jaeger; rm -r ~/otel trace_demo.py`

**Troubleshooting**

- No service in the dropdown: wait for the batch export, check port 4318 and the endpoint path `/v1/traces`.
- Traces broken into pieces: context is not propagated across HTTP calls (W3C `traceparent` header).
- Memory use grows: all-in-one stores in RAM; use a real backend for anything beyond a lab.

### Task 7.9: Predict disk exhaustion

- **What you will learn:** linear trend over history gives a "full in N days" warning. For production use Prometheus `predict_linear` (Task 7.5); this task shows the math with no dependencies.
- **Target distro:** both (Python 3). **Risk level:** `safe`.

```bash
sudo tee /usr/local/bin/disk-forecast.py >/dev/null <<'EOF'
#!/usr/bin/env python3
"""Predict when a filesystem fills, from a CSV of 'epoch_seconds,used_bytes' lines."""
import sys

def main(path, total_bytes):
    xs, ys = [], []
    with open(path) as fh:
        for line in fh:
            t, u = line.strip().split(",")
            xs.append(float(t)); ys.append(float(u))
    n = len(xs)
    if n < 3:
        sys.exit("need at least 3 samples")
    mx, my = sum(xs) / n, sum(ys) / n
    denom = sum((x - mx) ** 2 for x in xs)
    slope = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / denom
    if slope <= 0:
        print("usage is flat or falling: no fill date")
        return
    secs = (total_bytes - ys[-1]) / slope
    print(f"growth: {slope * 86400 / 1e9:.2f} GB/day; full in {secs / 86400:.1f} days")
    sys.exit(2 if secs < 7 * 86400 else 0)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: disk-forecast.py samples.csv TOTAL_BYTES")
    main(sys.argv[1], float(sys.argv[2]))
EOF
sudo chmod +x /usr/local/bin/disk-forecast.py

python3 - <<'EOF' > /tmp/samples.csv
now = 1760000000
for i in range(10):
    print(f"{now + i * 86400},{50e9 + i * 8e9}")
EOF
disk-forecast.py /tmp/samples.csv 200e9; echo "rc=$?"
```

To collect real data, append `date +%s,$(df --output=used -B1 / | tail -1)` to a CSV from a daily timer.

**Verify it worked.** Captured:

```text
growth: 8.00 GB/day; full in 9.8 days
rc=0
```

Exit code 2 means "full in under 7 days": wire that to an alert.

**Acceptance criteria**

- [ ] The script predicts 8 GB/day for the sample and exits 2 when the disk fills within 7 days (try a 130 GB disk).
- [ ] You can say when linear prediction is wrong (bursty or seasonal usage).

**Undo it:** `sudo rm /usr/local/bin/disk-forecast.py /tmp/samples.csv`

**Troubleshooting**

- `ZeroDivisionError`: all samples have the same timestamp.
- Negative slope after cleanup: expected, the script says "no fill date".
- Samples too few or too noisy: collect for at least a week.

---

## Step checklist

- [ ] 7.1 Top-process log
- [ ] 7.2 Connection log + timer
- [ ] 7.3 Nagios-style checks
- [ ] 7.4 Prometheus + Grafana
- [ ] 7.5 Alerts
- [ ] 7.6 sar reports
- [ ] 7.7 Loki + Grafana logs
- [ ] 7.8 Tracing
- [ ] 7.9 Disk forecast

## Further reading

- [Prometheus documentation](https://prometheus.io/docs/introduction/overview/): data model, PromQL and alerting.
- [Grafana Loki documentation](https://grafana.com/docs/loki/latest/): LogQL and deployment modes.
- [OpenTelemetry documentation](https://opentelemetry.io/docs/): instrumentation per language.
- [Brendan Gregg: Linux performance](https://www.brendangregg.com/linuxperf.html): the 60-second checklist and tool map.

**Next:** [Step 8: Disk Management](step-08-disk-mgmnt.md)
