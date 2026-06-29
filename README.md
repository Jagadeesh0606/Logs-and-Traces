# Logs-and-Traces
# Amazon Linux 2023 Observability Stack

A production-ready observability stack for **Amazon Linux 2023** using Grafana OSS, Loki, Grafana Alloy, Tempo, OpenTelemetry Collector, and Node Exporter.

This project provides a one-command installation for a complete monitoring, logging, and distributed tracing environment suitable for learning, development, and small production deployments.

---

# Architecture

```
                               +----------------------+
                               |      Grafana         |
                               |      Port :3000      |
                               +----------+-----------+
                                          |
                  +-----------------------+-----------------------+
                  |                                               |
                  |                                               |
                  ▼                                               ▼
          +---------------+                              +----------------+
          |     Loki      |                              |     Tempo      |
          |   Port 3100   |                              |   Port 3200    |
          +-------+-------+                              +--------+-------+
                  ▲                                               ▲
                  |                                               |
                  |                                               |
        +---------+----------+                       +------------+------------+
        |    Grafana Alloy   |                       | OpenTelemetry Collector |
        |                    |                       |       Port 4317          |
        +---------+----------+                       +------------+------------+
                  ▲                                               ▲
                  |                                               |
      +-----------+-----------+                         +----------+----------+
      | Linux Logs            |                         | Python Application  |
      | Apache Logs           |                         | OTLP Traces         |
      | Application Logs      |                         | Metrics             |
      +-----------------------+                         +---------------------+

                            +----------------------------+
                            |      Node Exporter         |
                            |       Port 9100            |
                            +----------------------------+
```

---

# Components

| Component               | Purpose                            |
| ----------------------- | ---------------------------------- |
| Grafana OSS             | Visualization and dashboards       |
| Loki                    | Centralized log aggregation        |
| Grafana Alloy           | Log collection (replaces Promtail) |
| Tempo                   | Distributed tracing                |
| OpenTelemetry Collector | OTLP receiver and exporter         |
| Node Exporter           | Linux host metrics                 |
| Python Sample App       | Demonstrates logs and traces       |

---

# Repository Structure

```
amazon-linux-2023-observability-stack/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── install.sh
├── uninstall.sh
├── verify.sh
│
├── scripts/
│   ├── common.sh
│   ├── install_grafana.sh
│   ├── install_loki.sh
│   ├── install_alloy.sh
│   ├── install_tempo.sh
│   ├── install_otel.sh
│   ├── install_node_exporter.sh
│   └── create_services.sh
│
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   └── dashboards/
│   └── dashboards/
│
├── loki/
│   ├── config.yaml
│   └── loki.service
│
├── alloy/
│   ├── config.alloy
│   └── alloy.service
│
├── tempo/
│   ├── tempo.yaml
│   └── tempo.service
│
├── otel/
│   ├── otelcol.yaml
│   └── otelcol.service
│
├── node-exporter/
│   └── node_exporter.service
│
├── sample-python-app/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
│
└── images/
    └── architecture.png
```

---

# Features

* One-command installation
* Amazon Linux 2023 compatible
* Latest Grafana OSS
* Loki TSDB storage
* Grafana Alloy log collection
* Tempo tracing backend
* OpenTelemetry Collector
* Node Exporter metrics
* Apache access/error log collection
* Linux system log collection
* Python application log collection
* Automatic Grafana datasource provisioning
* Ready-to-use dashboards
* Systemd service management
* Health verification script
* Uninstall script

---

# Prerequisites

* Amazon Linux 2023
* EC2 t3.medium or larger (recommended)
* Minimum 2 vCPUs
* Minimum 4 GB RAM
* Internet access
* sudo privileges

---

# Ports Used

| Service       | Port |
| ------------- | ---- |
| Grafana       | 3000 |
| Loki          | 3100 |
| Tempo         | 3200 |
| OTLP gRPC     | 4317 |
| OTLP HTTP     | 4318 |
| Node Exporter | 9100 |

---

# Installation

Clone the repository:

```bash
git clone https://github.com/<your-github-username>/amazon-linux-2023-observability-stack.git

cd amazon-linux-2023-observability-stack
```

Grant execute permissions:

```bash
chmod +x install.sh
chmod +x verify.sh
chmod +x uninstall.sh
```

Install the stack:

```bash
sudo ./install.sh
```

---

# Verify Installation

```bash
sudo ./verify.sh
```

---

# Default URLs

Grafana

```
http://<SERVER-IP>:3000
```

Loki

```
http://<SERVER-IP>:3100
```

Tempo

```
http://<SERVER-IP>:3200
```

Node Exporter

```
http://<SERVER-IP>:9100/metrics
```

---

# Default Grafana Login

```
Username: admin

Password: admin
```

Grafana prompts you to change the password on first login.

---

# Collected Logs

The default Grafana Alloy configuration collects:

```
/var/log/messages

/var/log/secure

/var/log/httpd/access_log

/var/log/httpd/error_log

/var/log/python-app/*.log
```

---

# Distributed Tracing

Applications send OTLP traces to:

```
http://localhost:4317
```

OpenTelemetry Collector forwards traces to Tempo.

---

# Dashboards Included

* Linux Server Monitoring
* Node Exporter
* Apache Access Logs
* Apache Error Logs
* Python Application Logs
* Loki Log Explorer
* Tempo Trace Explorer

---

# Health Check

The `verify.sh` script checks:

* Grafana
* Loki
* Tempo
* Grafana Alloy
* OpenTelemetry Collector
* Node Exporter

and verifies that all services are active.

---

# Uninstall

```bash
sudo ./uninstall.sh
```

---

# Future Enhancements

* Prometheus integration
* Alertmanager
* Blackbox Exporter
* cAdvisor
* Docker monitoring
* Kubernetes support
* AWS CloudWatch exporter
* AWS EC2 discovery
* AWS ALB metrics
* AWS RDS metrics
* AWS S3 metrics
* AWS Lambda monitoring
* Jaeger compatibility
* Multi-node Loki deployment
* High Availability Grafana

---

# License

This project is released under the MIT License.

---

# Author

Created as a hands-on Amazon Linux 2023 observability project using:

* Grafana OSS
* Loki
* Grafana Alloy
* Tempo
* OpenTelemetry Collector
* Node Exporter
