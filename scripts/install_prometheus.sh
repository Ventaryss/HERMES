#!/bin/bash

# Créer le répertoire de configuration Prometheus
mkdir -p ~/lpi-monitoring/configs/prometheus

# Créer un fichier de configuration Prometheus par défaut
cat <<EOL > ~/lpi-monitoring/configs/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'influxdb'
    static_configs:
      - targets: ['influxdb:8086']

  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']

  - job_name: 'loki'
    static_configs:
      - targets: ['loki:3100']

  - job_name: 'promtail'
    static_configs:
      - targets: ['promtail:9080']
EOL

# Use the specific docker-compose file for Prometheus
docker compose -f ~/lpi-monitoring/docker/docker-compose-prometheus.yml up -d
