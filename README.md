# LPI Monitoring Stack

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Directory Structure](#directory-structure)
- [Services](#services)
- [Installation](#installation)
- [Usage](#usage)
- [Advantages](#advantages)
- [Client Setup](#client-setup)
- [Contributing](#contributing)
- [License](#license)

## Introduction

Welcome to the LPI Monitoring Stack! This project provides a comprehensive logging and monitoring solution using a combination of Grafana, Prometheus, Loki, InfluxDB, Fluentd, and more. The setup is designed for easy deployment using Docker Compose, and can be customized to fit specific monitoring needs.

## Features

- **Centralized Logging**: Aggregate logs from multiple sources.
- **Real-time Monitoring**: Monitor system metrics and logs in real-time.
- **Customizable Dashboards**: Pre-configured Grafana dashboards.
- **Persistence**: Log and data persistence to avoid data loss on container restarts.
- **Scalable**: Easily add more services or scale existing ones.

## Directory Structure

The project is organized as follows:

```plaintext
LPI/
├── install.sh
├── configs/
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── promtail/
│   │   └── promtail-config.yaml
│   ├── fluentd/
│   │   └── fluent.conf
│   └── rsyslog/
│       └── 01-pfsense-to-fluentd.conf
├── docker/
│   └── docker-compose.yml
├── scripts/
│   ├── install_docker.sh
│   ├── install_docker_compose.sh
│   ├── install_rsyslog.sh
│   └── setup_persistence.sh
├── dashboards/
│   └── default_dashboard.json
└── client/
    ├── install_client.sh
    └── README.md
```

## Services

- **Grafana**: Data visualization & monitoring.
- **Prometheus**: Time-series database for metrics.
- **Loki**: Log aggregation system.
- **Promtail**: Log shipping for Loki.
- **InfluxDB**: Time-series database.
- **Fluentd**: Data collector for logs.
- **Rsyslog**: System log collector.

## Installation

### Prerequisites

- Docker
- Docker Compose

### Steps

1. **Clone the Repository**

    ```bash
    git clone https://github.com/Ventaryss/lpi-monitoring.git
    cd lpi-monitoring
    ```

2. **Run the Installation Script**

    ```bash
    chmod +x install.sh
    ./install.sh
    ```

This script will:
- Stop and remove existing Docker containers related to this setup.
- Install Docker Compose if not already installed.
- Install `rsyslog` if not already installed.
- Create necessary directories and set permissions.
- Create configuration files for Prometheus, Promtail, Fluentd, and Rsyslog.
- Start the services using Docker Compose.

## Usage

After installation, you can access the services at the following URLs:

- **Grafana**: `http://localhost:3000`
- **Prometheus**: `http://localhost:9090`
- **Loki**: `http://localhost:3100`
- **InfluxDB**: `http://localhost:8086`

Log in to Grafana with the default credentials (`admin/admin`) and start customizing your dashboards.

## Advantages

- **Easy Deployment**: Quickly set up a comprehensive monitoring stack with a single script.
- **Persistence**: Data and logs are persisted on the host machine to prevent data loss.
- **Customizable**: Easily add or modify services and configurations.
- **Pre-configured Dashboards**: Start with default Grafana dashboards tailored for your monitoring needs.

## Client Setup

To forward logs from client machines to this monitoring stack, follow these steps:

1. **Copy the `client/install_client.sh` script to the client machine.**
2. **Run the script on the client machine.**

    ```bash
    chmod +x install_client.sh
    ./install_client.sh
    ```

This will set up the necessary configurations on the client machine to forward logs to the server.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes. Ensure your code adheres to the project's coding standards and include relevant tests.
