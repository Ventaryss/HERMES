# LPI Monitoring Stack
Vérifier connexion palo et storm : Configurer Palo Alto et Stormshield pour envoyer des logs vers votre serveur Fluentd:

    Palo Alto:
        Accédez à l'interface de gestion de Palo Alto.
        Configurez un nouveau serveur syslog et définissez l'adresse IP de votre serveur Fluentd et le port 24226.
    Stormshield:
        Accédez à l'interface de gestion de Stormshield.
        Configurez un nouveau serveur syslog et définissez l'adresse IP de votre serveur Fluentd et le port 24225.

Puis aller sur grafana et voir dans le dashboard loki / app ; et mettre le job : palo alto ou job : stormshield
Si jamais rien ne s'affiche dans les logs, il faut regarder le fichier /scripts/install_rsyslog.sh et /scripts/install_fluentd pour voir dans les filtres s'il modifier les parties qui détecte qui est qui (donc voir les hostnames)

Install réperroire opt
1 ligne pour le deploiement
ajout des ref stormshirls, esxi etc

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Directory Structure](#directory-structure)
- [Services](#services)
- [Installation](#installation)
- [Usage](#usage)
- [Advantages](#advantages)
- [Client Setup](#client-setup)
- [Log Filtering and Archiving](#log-filtering-and-archiving)
- [Contributing](#contributing)

## Introduction
Welcome to the LPI Monitoring Stack! This project provides a comprehensive logging and monitoring solution using a combination of Grafana, Prometheus, Loki, InfluxDB, Fluentd, and more. The setup is designed for easy deployment using Docker Compose and can be customized to fit specific monitoring needs. This README will guide you through the installation, configuration, and usage of the stack.
## Features
- **Centralized Logging**: Aggregate logs from multiple sources into a single platform.
- **Real-time Monitoring**: Monitor system metrics and logs in real-time using Grafana dashboards.
- **Customizable Dashboards**: Pre-configured Grafana dashboards for a quick start, with options for further customization.
- **Persistence**: Ensure log and data persistence to avoid data loss on container restarts.
- **Scalable**: Easily add more services or scale existing ones to accommodate your needs.
- **Automatic Restart**: Docker containers automatically restart if the VM reboots.
- **Dynamic Configuration Reload**: Support for dynamic reloading of configurations without restarting services.
- **Detailed Logging**: Comprehensive log formats for detailed analysis.
- **Client Log Shipping**: Seamless setup for client machines to forward logs to the central server.
- **Scheduled Log Archiving**: Automatically archive logs weekly to maintain a clean log directory.
## Directory Structure
The project is organized as follows:
```plaintext
LPI/
├── install.sh
├── configs/
│   ├── grafana/
│   ├── loki/
│   │   └── loki-config.yaml
│   ├── prometheus/
@@ -80,10 +58,13 @@ LPI/
│   ├── install_rsyslog.sh
│   └── install_script_logs.sh
├── dashboards_grafana/
│   ├── loki/
│   ├── prometheus/
│   ├── influxDB/
│   └── pfsense/
├── loki-wal/
├── loki-logs/
└── client/
@@ -92,102 +73,120 @@ LPI/
## Services
- **Grafana**: Data visualization & monitoring. Access at `http://localhost:3000`.
- **Prometheus**: Time-series database for metrics. Access at `http://localhost:9090`.
- **Loki**: Log aggregation system. Access at `http://localhost:3100`.
- **Promtail**: Log shipping for Loki.
- **InfluxDB**: Time-series database. Access at `http://localhost:8086`.
- **Fluentd**: Data collector for logs.
- **Rsyslog**: System log collector.
## Installation
### Prerequisites
- Docker
- Docker Compose
The installation script will automatically check for and install these prerequisites if they are not already present on your system.
### Steps
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

### Loki WAL

Loki's WAL (Write-Ahead Log) is used to provide durability and improve performance. It ensures that incoming log entries are first written to a log file before being processed and stored. This helps in data recovery in case of a system crash or failure. The `loki-wal` directory is used to store these log files.

## Usage

After installation, you can access the services at the following URLs:

- **Grafana**: `http://localhost:3000`
- **Prometheus**: `http://localhost:9090`
- **Loki**: `http://localhost:3100`
- **InfluxDB**: `http://localhost:8086`

Log in to Grafana with the default credentials (`admin/admin`) and start customizing your dashboards.

### Dynamic Configuration Reload

For services supporting dynamic configuration reload, you can update their configurations without restarting the containers:

- **Prometheus**: Reload configuration with:
    ```bash
    curl -X POST http://localhost:9090/-/reload
    ```
- **Fluentd**: Reload configuration with:
    ```bash
    docker exec <fluentd_container_id> kill -USR1 1
    ```

## Advantages

- **Easy Deployment**: Quickly set up a comprehensive monitoring stack with a single script.
- **Persistence**: Data and logs are persisted on the host machine to prevent data loss.
- **Customizable**: Easily add or modify services and configurations.
- **Pre-configured Dashboards**: Start with default Grafana dashboards tailored for your monitoring needs.
- **Automatic Restart**: Docker containers automatically restart if the VM reboots.
- **Detailed Log Analysis**: Use comprehensive log formats for detailed analysis.
- **Scheduled Log Archiving**: Automatically archive logs weekly to maintain a clean log directory.

## Client Setup

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

## Log Filtering and Archiving
@@ -196,20 +195,50 @@ This script will:

The setup includes detailed log filtering rules to separate logs based on their source and content:

- **pfSense Logs**: Logs containing "pfSense" are redirected to `/var/log/pfsense/pfsense.log`.
- **Client Logs**: Logs from client machines (not originating from `127.0.0.1`) are redirected to `/var/log/client_logs/client.log`.

These rules are defined in the `rsyslog` configuration:

```plaintext
:msg, contains, "pfSense" /var/log/pfsense/pfsense.log
if $fromhost-ip != '127.0.0.1' then /var/log/client_logs/client.log
```

### Scheduled Log Archiving

The `install_script_logs.sh` script sets up a cron job to archive logs weekly. It runs every Monday at 6 AM, compressing logs from the previous week and storing them in the `loki-logs` directory.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes. Ensure your code adheres to the project's coding standards and includes relevant tests.
