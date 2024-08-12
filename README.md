Certainly! Here's a revised and organized version of your README for the LPI Monitoring Stack project:

```markdown
# LPI Monitoring Stack

## Introduction

Welcome to the LPI Monitoring Stack! This project offers a comprehensive logging and monitoring solution using Grafana, Prometheus, Loki, InfluxDB, Fluentd, and more. Designed for easy deployment with Docker Compose, it can be customized to meet specific monitoring needs. This README will guide you through installation, configuration, and usage.

## Features

- **Centralized Logging:** Aggregate logs from multiple sources.
- **Real-time Monitoring:** Monitor metrics and logs in real-time with Grafana.
- **Customizable Dashboards:** Pre-configured Grafana dashboards with customization options.
- **Persistence:** Ensure data persistence to avoid loss on container restarts.
- **Scalable:** Easily add or scale services.
- **Automatic Restart:** Containers restart automatically if the VM reboots.
- **Dynamic Configuration Reload:** Update configurations without restarting services.
- **Detailed Logging:** Comprehensive log formats for analysis.
- **Client Log Shipping:** Forward logs from client machines to the server.
- **Scheduled Log Archiving:** Weekly log archiving to maintain a clean directory.

## Directory Structure

The project is organized as follows:

```
LPI/
├── install.sh
├── configs/
│   ├── grafana/
│   │   └── provisioning/
│   │       ├── dashboards/
│   │       │   └── dashboard.yaml
│   │       └── datasources/
│   │           └── datasource.yaml
│   ├── loki/
│   │   └── loki-config.yaml
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── promtail/
│   │   └── promtail-config.yaml
│   └── fluentd/
│       └── fluent.conf
├── docker/
│   ├── docker-compose-fluentd.yml
│   ├── docker-compose-grafana.yml
│   ├── docker-compose-influxdb.yml
│   ├── docker-compose-loki.yml
│   ├── docker-compose-prometheus.yml
│   ├── docker-compose-promtail.yml
│   └── docker-compose-compose.yml
├── scripts/
│   ├── install_fluentd.sh
│   ├── install_grafana.sh
│   ├── install_influxdb.sh
│   ├── install_loki.sh
│   ├── install_prometheus.sh
│   ├── install_promtail.sh
│   ├── install_rsyslog.sh
│   └── install_script_logs.sh
├── dashboards_grafana/
│   ├── Proxmox7.json
│   ├── Proxmox_Cluster.json
│   ├── pfSense_System.json
│   ├── pfSense_Node_Exporter.json
│   ├── ESXI.json
│   ├── Logs_App.json
│   └── default_dashboard.json
├── loki-wal/
├── loki-logs/
└── client/
    └── install_client.sh
```

## Services

- **Grafana:** Data visualization & monitoring. Access at [http://localhost:3000](http://localhost:3000).
- **Prometheus:** Time-series database for metrics. Access at [http://localhost:9090](http://localhost:9090).
- **Loki:** Log aggregation system. Access at [http://localhost:3100](http://localhost:3100).
- **Promtail:** Log shipping for Loki.
- **InfluxDB:** Time-series database. Access at [http://localhost:8086](http://localhost:8086).
- **Fluentd:** Data collector for logs.
- **Rsyslog:** System log collector.

## Installation

### Prerequisites

- **Docker:** Required for containerized applications.
- **Docker Compose:** Orchestrates multi-container applications.

The installation script checks for and installs these prerequisites if needed.

### Steps

#### Clone the Repository

```bash
git clone https://github.com/Ventaryss/lpi-monitoring
cd lpi-monitoring
```

#### Run the Installation Script

```bash
chmod +x install.sh
./install.sh
```

This script will:

- Display a menu to select services to install.
- Stop and remove existing Docker containers.
- Install Docker Compose and rsyslog if not installed.
- Create directories and set permissions.
- Create configuration files for Prometheus, Promtail, Fluentd, and Rsyslog.
- Start services using Docker Compose.

### Order of Service Installation

Ensure **InfluxDB** is installed before **Grafana** to configure Grafana's connection to InfluxDB using the generated token.

### Loki WAL

Loki's WAL (Write-Ahead Log) provides durability and performance. It writes log entries to a file before processing, aiding data recovery in case of a crash.

## Usage

Access services at the following URLs:

- **Grafana:** [http://localhost:3000](http://localhost:3000)
- **Prometheus:** [http://localhost:9090](http://localhost:9090)
- **Loki:** [http://localhost:3100](http://localhost:3100)
- **InfluxDB:** [http://localhost:8086](http://localhost:8086)

Log in to Grafana with default credentials (admin/admin) and customize dashboards.

### Configuring InfluxDB Connection in Grafana

1. Ensure InfluxDB is running and **install_influxdb.sh** has been executed.
2. Use the following configuration in Grafana:

- **Organization:** `lpi`
- **Bucket:** `logs`
- **Token:** Use the token from **install_influxdb.sh**.

### Dynamic Configuration Reload

Update configurations without restarting containers:

- **Prometheus:** Reload with:
  ```bash
  curl -X POST http://localhost:9090/-/reload
  ```
- **Fluentd:** Reload with:
  ```bash
  docker exec kill -USR1 1
  ```

## Advantages

- **Easy Deployment:** Set up with a single script.
- **Persistence:** Data and logs are persisted on the host.
- **Customizable:** Modify services and configurations easily.
- **Pre-configured Dashboards:** Start with default Grafana dashboards.
- **Automatic Restart:** Containers restart on VM reboot.
- **Detailed Log Analysis:** Use comprehensive log formats.
- **Scheduled Log Archiving:** Weekly log archiving.

## Client Setup

To forward logs from client machines:

1. Copy `client/install_client.sh` to the client machine.
2. Edit the script to set the `SERVER_IP` variable.
3. Run the script:

```bash
chmod +x install_client.sh
./install_client.sh
```

This script will:

- Prompt for Node Exporter installation.
- Install and configure rsyslog to forward logs.
- Optionally install Node Exporter for system metrics.

## Log Filtering and Archiving

### Log Filtering

The setup includes log filtering rules:

- **pfSense Logs:** Redirected to `/var/log/pfsense/pfsense.log`.
- **Stormshield Logs:** Redirected to `/var/log/stormshield/stormshield.log`.
- **Palo Alto Logs:** Redirected to `/var/log/paloalto/paloalto.log`.

Defined in rsyslog configuration:

```plaintext
:hostname, contains, "pfSense" /var/log/pfsense/pfsense.log
:hostname, contains, "stormshield" /var/log/stormshield/stormshield.log
:hostname, contains, "paloalto" /var/log/paloalto/paloalto.log
```

### Scheduled Log Archiving

The `install_script_logs.sh` script sets up a cron job for weekly log archiving every Monday at 6 AM, storing compressed logs in the loki-logs directory.

## Contributing

Contributions are welcome! Fork the repository and submit a pull request with your changes. Ensure your code adheres to coding standards and includes relevant tests.

## Additional Setup

### InfluxDB Configuration in install_influxdb.sh

Ensure these variables are set in **install_influxdb.sh**:

```bash
ORG_NAME="lpi"
BUCKET_NAME="logs"
INFLUXDB_USER="admin"
INFLUXDB_PASSWORD="adminadmin"
```

These set up InfluxDB and create the organization and bucket. Use the generated token in Grafana's configuration.

### Connecting Additional Services

To connect services like **Stormshield**, **Palo Alto**, or **ESXi**:

- Forward logs using rsyslog or another agent.
- Configure Fluentd or Promtail to parse and ship logs to Loki.
- Update Grafana dashboards to visualize logs and metrics.

This README provides a comprehensive overview and detailed instructions for setting up and using the LPI Monitoring Stack. For more information or troubleshooting, refer to the individual service documentation included within each configuration file.
```

You can now copy and paste this formatted Markdown into your GitHub project's README file. Let me know if there's anything else you'd like to modify!

Citations:
[1] https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/21669470/c3d1063a-f9e1-4588-859e-9ad92f052a70/paste.txt
