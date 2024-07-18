#!/bin/bash

# Créer le répertoire de configuration Promtail
mkdir -p ~/LPI/configs/promtail

# Créer un fichier de configuration Promtail par défaut
cat <<EOL > ~/LPI/configs/promtail/promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 9081

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: pfsense
    static_configs:
      - targets:
          - localhost
        labels:
          job: pfsense
          __path__: /var/log/pfsense/*.log
    pipeline_stages:
      - regex:
          expression: '^(?P<timestamp>\w+\s+\d+\s+\d{2}:\d{2}:\d{2})\s+(?P<host>[^\s]+)\s+(?P<program>[^\[]+)\[(?P<pid>\d+)\]:\s+(?P<message>.*)$'
      - regex:
          expression: 'rule (?P<rule_number>\d+).+?(?P<action>\w+)\s+(?P<protocol>\w+)\s+from\s+(?P<src_ip>[^\s]+)\s+to\s+(?P<dst_ip>[^\s]+)\s+dst-port\s+(?P<dst_port>\d+)'
          source: message
      - labels:
          action:
          protocol:
          src_ip:
          dst_ip:
          dst_port:

  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  - job_name: grafana
    static_configs:
      - targets:
          - localhost
        labels:
          job: grafana
          __path__: /var/log/grafana/grafana.log

  - job_name: prometheus
    static_configs:
      - targets:
          - localhost
        labels:
          job: prometheus
          __path__: /prometheus/*log

  - job_name: loki
    static_configs:
      - targets:
          - localhost
        labels:
          job: loki
          __path__: /loki/*log

  - job_name: influxdb
    static_configs:
      - targets:
          - localhost
        labels:
          job: influxdb
          __path__: /var/log/influxdb/*log

  - job_name: client_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: client_logs
          host: __HOSTNAME__
          __path__: /var/log/client_logs/*.log
EOL

# Use the specific docker-compose file for Promtail
docker compose -f ~/LPI/docker/docker-compose-promtail.yml up -d
