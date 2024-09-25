### **LPI Monitoring Stack**

## **Table of Contents**
1. [Introduction](#introduction)
2. [Features](#features)
3. [Directory Structure](#directory-structure)
4. [Services](#services)
5. [Installation](#installation)
6. [Usage](#usage)
7. [Advantages](#advantages)
8. [Client Setup](#client-setup)
9. [Log Filtering and Archiving](#log-filtering-and-archiving)
10. [Configuring Firewall Integration](#configuring-firewall-integration)
11. [Contributing](#contributing)

## **Introduction**

Welcome to the LPI Monitoring Stack! This project provides a comprehensive logging and monitoring solution using Grafana, Prometheus, Loki, InfluxDB, Fluentd, and more. The setup is designed for easy deployment using Docker Compose and can be customized to fit specific monitoring needs, including integration with various firewalls such as pfSense, Palo Alto, and Stormshield. This README will guide you through the installation, configuration, and usage of the stack.

## **Features**
- **Centralized Logging**: Aggregate logs from multiple sources into a single platform.
- **Real-time Monitoring**: Monitor system metrics and logs in real-time using Grafana dashboards.
- **Customizable Dashboards**: Pre-configured Grafana dashboards for a quick start, with options for further customization.
- **Persistence**: Ensure log and data persistence to avoid data loss on container restarts.
- **Scalable**: Easily add more services or scale existing ones to accommodate your needs.
- **Automatic Restart**: Docker containers automatically restart if the VM reboots.
- **Dynamic Configuration Reload**: Support for dynamic reloading of configurations without restarting services.
- **Detailed Logging**: Comprehensive log formats for detailed analysis.
- **Firewall Integration**: Easily integrate and collect logs from pfSense, Palo Alto, Stormshield, and more.
- **Client Log Shipping**: Seamless setup for client machines to forward logs to the central server.
- **Scheduled Log Archiving**: Automatically archive logs weekly to maintain a clean log directory.

## **Directory Structure**

The project is organized as follows:

```
LPI/
├── install.sh
├── configs/
│   ├── grafana/
│   │   ├── provisioning/
│   │   │   ├── dashboards/
│   │   │   └── datasources/
│   ├── loki/
│   │   └── loki-config.yaml
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── fluentd/
│   │   └── fluent.conf
│   ├── promtail/
│   │   └── promtail-config.yaml
│   └── rsyslog/
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
├── loki-wal/
├── Archives_Logs/
│   ├── loki_logs_archives/
│   ├── prometheus_logs_archives/
│   ├── grafana_logs_archives/
│   ├── fluentd_logs_archives/
│   ├── rsyslog_logs_archives/
│   ├── pfsense_logs_archives/
│   ├── stormshield_logs_archives/
│   └── paloalto_logs_archives/
├── docker/
│   ├── docker-compose-fluentd.yml
│   ├── docker-compose-grafana.yml
│   ├── docker-compose-influxdb.yml
│   ├── docker-compose-loki.yml
│   ├── docker-compose-prometheus.yml
│   ├── docker-compose-promtail.yml
└── client/
    └── install_client.sh

```

## **Services**
- **Grafana**: Data visualization & monitoring. Access at `http://localhost:3000`.
- **Prometheus**: Time-series database for metrics. Access at `http://localhost:9090`.
- **Loki**: Log aggregation system. Access at `http://localhost:3100`.
- **Promtail**: Log shipping for Loki.
- **InfluxDB**: Time-series database. Access at `http://localhost:8086`.
- **Fluentd**: Data collector for logs.
- **Rsyslog**: System log collector.

## **Installation**

### **Prerequisites**
- Docker
- Docker Compose

The installation script will automatically check for and install these prerequisites if they are not already present on your system.

### **Steps**
1. **Clone the Repository**
    ```bash
    git clone https://github.com/Ventaryss/lpi-monitoring
    cd lpi-monitoring
    ```

2. **Run the Installation Script**
    ```bash
    chmod +x install.sh
    ./install.sh
    ```

This script will:
- Display a menu to select the services to install.
- Stop and remove existing Docker containers related to this setup.
- Install Docker Compose if not already installed.
- Install `rsyslog` if not already installed.
- Create necessary directories and set permissions.
- Create configuration files for Prometheus, Promtail, Fluentd, and Rsyslog.
- Start the services using Docker Compose.

## **Usage**

After installation, you can access the services at the following URLs:

- **Grafana**: `http://localhost:3000`
- **Prometheus**: `http://localhost:9090`
- **Loki**: `http://localhost:3100`
- **InfluxDB**: `http://localhost:8086`

Log in to Grafana with the default credentials (`admin/admin`) and start customizing your dashboards.

### **Dynamic Configuration Reload**

For services supporting dynamic configuration reload, you can update their configurations without restarting the containers:

- **Prometheus**: Reload configuration with:
    ```bash
    curl -X POST http://localhost:9090/-/reload
    ```
- **Fluentd**: Reload configuration with:
    ```bash
    docker exec <fluentd_container_id> kill -USR1 1
    ```

## **Advantages**

- **Easy Deployment**: Quickly set up a comprehensive monitoring stack with a single script.
- **Persistence**: Data and logs are persisted on the host machine to prevent data loss.
- **Customizable**: Easily add or modify services and configurations.
- **Pre-configured Dashboards**: Start with default Grafana dashboards tailored for your monitoring needs.
- **Automatic Restart**: Docker containers automatically restart if the VM reboots.
- **Detailed Log Analysis**: Use comprehensive log formats for detailed analysis.
- **Scheduled Log Archiving**: Automatically archive logs weekly to maintain a clean log directory.

## **Client Setup**

To forward logs from client machines to this monitoring stack, follow these steps:

1. **Copy the `client/install_client.sh` script to the client machine.**
2. **Edit the script to set the correct `SERVER_IP` variable.**
3. **Run the script on the client machine.**

    ```bash
    chmod +x install_client.sh
    ./install_client.sh
    ```

This script will:
- Prompt the user if they want to install Node Exporter.
- Install and configure `rsyslog` to forward logs to the central server.
- Optionally install Node Exporter to provide system metrics to Prometheus.

## **Log Filtering and Archiving**

The setup includes detailed log filtering rules to separate logs based on their source and content:

- **pfSense Logs**: Logs containing "pfSense" are redirected to `/var/log/pfsense/pfsense.log`.
- **Client Logs**: Logs from client machines (not originating from `127.0.0.1`) are redirected to `/var/log/client_logs/client.log`.
- **Palo Alto Logs**: Forwarded from port 5142 and saved in `/var/log/paloalto/paloalto.log`.
- **Stormshield Logs**: Forwarded from port 5141 and saved in `/var/log/stormshield/stormshield.log`.

These rules are defined in the `rsyslog` configuration:

```plaintext
:msg, contains, "pfSense" /var/log/pfsense/pfsense.log
if $fromhost-ip != '127.0.0.1' then /var/log/client_logs/client.log
:hostname, contains, "paloalto" /var/log/paloalto/paloalto.log
:hostname, contains, "stormshield" /var/log/stormshield/stormshield.log
```

### **Scheduled Log Archiving**

Logs are automatically archived weekly to maintain a clean directory structure. The `install_script_logs.sh` script sets up a cron job to archive logs every Sunday at 23:00, compressing them into a specific directory.

## **Configuring Firewall Integration**

This stack supports integration with various firewalls such as **pfSense**, **Palo Alto**, and **Stormshield**. To configure a firewall:
1. **Update the `rsyslog` configuration**: Edit `/etc/rsyslog.d/forward-logs.conf` to set the correct port and filtering rules for your firewall logs.
2. **Forward logs from the firewall to the monitoring server**: Configure your firewall to send logs to the IP address of your monitoring stack on the designated port.
3. **Restart `rsyslog`** to apply changes: 
    ```bash
    sudo systemctl restart rsyslog
    ```

## **Contributing**

Contributions are welcome! Please fork the repository, make your changes, and submit a pull request. Ensure your code adheres to the project's coding standards and includes relevant tests.
