# Log Processing Infrastructure (LPI) Setup

## Overview

The Log Processing Infrastructure (LPI) setup script automates the deployment of essential logging and monitoring components using Docker containers. It integrates Grafana for visualization, Prometheus for metrics collection, Loki for log aggregation, InfluxDB for time-series data storage, Fluentd for log forwarding, and Promtail for log scraping and forwarding. This setup enhances visibility and monitoring capabilities within your network environment.

## Components Deployed

1. **Grafana**: Dashboard and visualization platform.
2. **Prometheus**: Monitoring and alerting toolkit.
3. **Loki**: Log aggregation system.
4. **Promtail**: Log scraper and forwarder.
5. **InfluxDB**: Time-series database.
6. **Fluentd**: Log collector and forwarder.

## Prerequisites

- **Docker**: Ensure Docker and Docker Compose are installed on your host system.
- **rsyslog**: Used for receiving syslog messages and forwarding them to Fluentd.
- **Access to pfSense logs**: Ensure pfSense is configured to send logs to the designated rsyslog server.

## Setup Steps

1. **Clone the Repository**:
   ```
   git clone <repository_url>
   cd LPI
   ```

2. **Run the Setup Script**:
   ```
   ./setup.sh
   ```
   - This script stops and removes existing Docker containers, installs Docker Compose if not already installed, installs rsyslog if not present, creates necessary directories, generates configuration files for Grafana, Prometheus, Loki, Promtail, InfluxDB, and Fluentd, sets up rsyslog to forward logs to Fluentd, and starts all Docker containers.

3. **Verify Deployment**:
   - Access Grafana at `http://localhost:3000` (default credentials admin/admin) to visualize metrics and logs.
   - Prometheus is accessible at `http://localhost:9090`.
   - Loki can be accessed at `http://localhost:3100`.
   - InfluxDB is accessible at `http://localhost:8086`.

## Configuration Details

- **Prometheus Configuration**:
  - Scrapes metrics from various services including itself, Grafana, InfluxDB, Loki, and Promtail.

- **Loki Configuration**:
  - Configured with storage options using boltdb and filesystem for storing index and log chunks respectively.

- **Promtail Configuration**:
  - Scrapes logs from `/var/log` directory and forwards them to Loki based on defined scrape configurations.

- **Fluentd Configuration**:
  - Listens for syslog messages from rsyslog on TCP/UDP port 24224 and forwards them to Loki with additional metadata and labels.

- **rsyslog Configuration**:
  - Listens for syslog messages from remote devices (e.g., pfSense) on UDP port 514 and forwards them to Fluentd.

## Adding pfSense Logs

To integrate pfSense logs into the LPI:

1. **Configure pfSense**:
   - Navigate to pfSense web interface.
   - Configure syslog to forward logs to the IP address of your rsyslog server (where Fluentd is listening).

2. **Verify Logs**:
   - Once configured, restart pfSense to start sending logs.
   - Logs from pfSense will be forwarded to Fluentd, processed with additional labels (e.g., job: pfsense_syslog), and stored in `/var/log/pfsense` on the host system.

## Additional Notes

- **Monitoring and Alerting**: Utilize Grafana and Prometheus for creating custom dashboards and setting up alerts based on metrics and logs.
- **Log Extraction**: The setup includes a scheduled job (`extract_loki_logs.sh`) to extract specific logs from Loki periodically for offline analysis.
