# LPI Monitoring Stack

## Introduction

Welcome to the LPI Monitoring Stack! This project provides a comprehensive logging and monitoring solution using a combination of Grafana, Prometheus, Loki, InfluxDB, Fluentd, and more. The setup is designed for easy deployment using Docker Compose and can be customized to fit specific monitoring needs. This README will guide you through the installation, configuration, and usage of the stack.

## Features

- **Centralized Logging:** Aggregate logs from multiple sources into a single platform.
- **Real-time Monitoring:** Monitor system metrics and logs in real-time using Grafana dashboards.
- **Customizable Dashboards:** Pre-configured Grafana dashboards for a quick start, with options for further customization.
- **Persistence:** Ensure log and data persistence to avoid data loss on container restarts.
- **Scalable:** Easily add more services or scale existing ones to accommodate your needs.
- **Automatic Restart:** Docker containers automatically restart if the VM reboots.
- **Dynamic Configuration Reload:** Support for dynamic reloading of configurations without restarting services.
- **Detailed Logging:** Comprehensive log formats for detailed analysis.
- **Client Log Shipping:** Seamless setup for client machines to forward logs to the central server.
- **Scheduled Log Archiving:** Automatically archive logs weekly to maintain a clean log directory.

## Directory Structure

The project is organized as follows:

LPI/
├── install.sh
├── configs/
│ ├── grafana/
│ │ └── provisioning/
│ │ ├── dashboards/
│ │ │ └── dashboard.yaml
│ │ └── datasources/
│ │ └── datasource.yaml
│ ├── loki/
│ │ └── loki-config.yaml
│ ├── prometheus/
│ │ └── prometheus.yml
│ ├── promtail/
│ │ └── promtail-config.yaml
│ └── fluentd/
│ └── fluent.conf
├── docker/
│ ├── docker-compose-fluentd.yml
│ ├── docker-compose-grafana.yml
│ ├── docker-compose-influxdb.yml
│ ├── docker-compose-loki.yml
│ ├── docker-compose-prometheus.yml
│ ├── docker-compose-promtail.yml
│ └── docker-compose-compose.yml
├── scripts/
│ ├── install_fluentd.sh
│ ├── install_grafana.sh
│ ├── install_influxdb.sh
│ ├── install_loki.sh
│ ├── install_prometheus.sh
│ ├── install_promtail.sh
│ ├── install_rsyslog.sh
│ └── install_script_logs.sh
├── dashboards_grafana/
│ ├── Proxmox7.json
│ ├── Proxmox_Cluster.json
│ ├── pfSense_System.json
│ ├── pfSense_Node_Exporter.json
│ ├── ESXI.json
│ ├── Logs_App.json
│ └── default_dashboard.json
├── loki-wal/
├── loki-logs/
└── client/
└── install_client.sh

markdown


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

- **Docker:** Required to run containerized applications.
- **Docker Compose:** Orchestrates multi-container Docker applications.

The installation script will automatically check for and install these prerequisites if they are not already present on your system.

### Steps

#### Clone the Repository

```bash
git clone https://github.com/Ventaryss/lpi-monitoring
cd lpi-monitoring

Run the Installation Script

bash

chmod +x install.sh
./install.sh

This script will:

    Display a menu to select the services to install.
    Stop and remove existing Docker containers related to this setup.
    Install Docker Compose if not already installed.
    Install rsyslog if not already installed.
    Create necessary directories and set permissions.
    Create configuration files for Prometheus, Promtail, Fluentd, and Rsyslog.
    Start the services using Docker Compose.

Order of Service Installation

Ensure that InfluxDB is installed before Grafana to correctly configure Grafana's connection to InfluxDB using the generated token.
Loki WAL

Loki's WAL (Write-Ahead Log) is used to provide durability and improve performance. It ensures that incoming log entries are first written to a log file before being processed and stored. This helps in data recovery in case of a system crash or failure. The loki-wal directory is used to store these log files.
Usage

After installation, you can access the services at the following URLs:

    Grafana: http://localhost:3000
    Prometheus: http://localhost:9090
    Loki: http://localhost:3100
    InfluxDB: http://localhost:8086

Log in to Grafana with the default credentials (admin/admin) and start customizing your dashboards.
Configuring InfluxDB Connection in Grafana

    Ensure InfluxDB is running and the install_influxdb.sh script has been executed.
    Use the following configuration in the Grafana datasource setup:

    Organization: lpi
    Bucket: logs
    Token: Use the token generated by the install_influxdb.sh script.

Dynamic Configuration Reload

For services supporting dynamic configuration reload, you can update their configurations without restarting the containers:

    Prometheus: Reload configuration with:

    bash

curl -X POST http://localhost:9090/-/reload

Fluentd: Reload configuration with:

bash

    docker exec <fluentd_container_id> kill -USR1 1

Advantages

    Easy Deployment: Quickly set up a comprehensive monitoring stack with a single script.
    Persistence: Data and logs are persisted on the host machine to prevent data loss.
    Customizable: Easily add or modify services and configurations.
    Pre-configured Dashboards: Start with default Grafana dashboards tailored for your monitoring needs.
    Automatic Restart: Docker containers automatically restart if the VM reboots.
    Detailed Log Analysis: Use comprehensive log formats for detailed analysis.
    Scheduled Log Archiving: Automatically archive logs weekly to maintain a clean log directory.

Client Setup

To forward logs from client machines to this monitoring stack, follow these steps:

    Copy the client/install_client.sh script to the client machine.
    Edit the script to set the correct SERVER_IP variable.
    Run the script on the client machine:

bash

chmod +x install_client.sh
./install_client.sh

This script will:

    Prompt the user if they want to install Node Exporter.
    Install and configure rsyslog to forward logs to the central server.
    Optionally install Node Exporter to provide system metrics to Prometheus.

Log Filtering and Archiving
Log Filtering

The setup includes detailed log filtering rules to separate logs based on their source and content:

    pfSense Logs: Logs containing "pfSense" are redirected to /var/log/pfsense/pfsense.log.
    Stormshield Logs: Logs containing "stormshield" are redirected to /var/log/stormshield/stormshield.log.
    Palo Alto Logs: Logs containing "paloalto" are redirected to /var/log/paloalto/paloalto.log.

These rules are defined in the rsyslog configuration:

rsyslog

:hostname, contains, "pfSense" /var/log/pfsense/pfsense.log
:hostname, contains, "stormshield" /var/log/stormshield/stormshield.log
:hostname, contains, "paloalto" /var/log/paloalto/paloalto.log

Scheduled Log Archiving

The install_script_logs.sh script sets up a cron job to archive logs weekly. It runs every Monday at 6 AM, compressing logs from the previous week and storing them in the loki-logs directory.
Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes. Ensure your code adheres to the project's coding standards and includes relevant tests.
Additional Setup
InfluxDB Configuration in install_influxdb.sh

Ensure the following variables are correctly set in the install_influxdb.sh script:

bash

ORG_NAME="lpi"
BUCKET_NAME="logs"
INFLUXDB_USER="admin"
INFLUXDB_PASSWORD="adminadmin"

These variables will set up the InfluxDB instance and create the necessary organization and bucket. The script will also output the generated token, which you should use in Grafana's datasource configuration.
Connecting Additional Services

To connect services like Stormshield, Palo Alto, or an ESXi host:

    Ensure the appropriate logs are being forwarded to the monitoring stack using rsyslog or another logging agent.
    Configure Fluentd or Promtail to parse and ship these logs to Loki.
    Create or update Grafana dashboards to visualize the logs and metrics from these sources.

This README provides a comprehensive overview and detailed instructions for setting up and using the LPI Monitoring Stack. For more information or troubleshooting, refer to the individual service documentation included within each configuration file.
