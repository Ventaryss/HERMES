#!/bin/bash

# Environment variables
export LPI_DIR=~/LPI
export LOKI_NETWORK_SUBNET=10.0.30.0/24

# Stop and remove existing Docker containers if they exist
containers=$(docker ps -a -q --filter "name=loki" --filter "name=prometheus" --filter "name=grafana" --filter "name=influxdb" --filter "name=fluentd" --filter "name=promtail")
if [ -n "$containers" ]; then
    docker stop $containers
    docker rm $containers
else
    echo "No existing containers to stop or remove."
fi

# Initialize Docker Swarm
docker swarm init

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

# Install rsyslog if not already installed
if ! command -v rsyslogd &> /dev/null
then
    echo "rsyslog not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y rsyslog rsyslog-relp
else
    echo "rsyslog is already installed."
fi

# Create directories for LPI and configuration files
mkdir -p $LPI_DIR/promtail $LPI_DIR/prometheus $LPI_DIR/loki $LPI_DIR/loki-wal $LPI_DIR/loki-logs $LPI_DIR/fluentd $LPI_DIR/pfsense-logs

# Set permissions for Loki WAL directory
sudo chown -R 10001:10001 $LPI_DIR/loki-wal

# Create Docker secrets
echo "grafana_password" | docker secret create grafana_password -
echo "loki_password" | docker secret create loki_password -

# Create docker-compose.yml
cat <<EOL > $LPI_DIR/docker-compose.yml
version: '3.8'

services:
  grafana:
    image: grafana/grafana:latest
    user: "472:472"
    ports:
      - "127.0.0.1:3000:3000"
    volumes:
      - grafana-storage:/var/lib/grafana:rw
    secrets:
      - grafana_password
    environment:
      - GF_SECURITY_ADMIN_PASSWORD_FILE=/run/secrets/grafana_password
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
    read_only: true
    tmpfs: /run:rw,noexec,nosuid,size=65536k

  prometheus:
    image: prom/prometheus:latest
    user: "65534:65534"
    ports:
      - "127.0.0.1:9090:9090"
    volumes:
      - prometheus-storage:/prometheus:rw
      - $LPI_DIR/prometheus:/etc/prometheus:ro
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3
    read_only: true
    tmpfs: /run:rw,noexec,nosuid,size=65536k

  loki:
    image: grafana/loki:2.8.0
    user: "10001:10001"
    ports:
      - "127.0.0.1:3100:3100"
    volumes:
      - loki-storage:/loki:rw
      - $LPI_DIR/loki:/etc/loki:ro
      - $LPI_DIR/loki-wal:/wal:rw
    command: -config.file=/etc/loki/loki-config.yaml
    secrets:
      - loki_password
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:3100/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
    read_only: true
    tmpfs: /run:rw,noexec,nosuid,size=65536k

  promtail:
    image: grafana/promtail:latest
    user: "65534:65534"
    ports:
      - "514:514/udp"
    volumes:
      - $LPI_DIR/promtail:/etc/promtail:ro
      - /var/log:/var/log:ro
    command: -config.file=/etc/promtail/promtail-config.yaml
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:9080/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
    read_only: true
    tmpfs: /run:rw,noexec,nosuid,size=65536k

  influxdb:
    image: influxdb:latest
    user: "999:999"
    ports:
      - "127.0.0.1:8086:8086"
    volumes:
      - influxdb-storage:/var/lib/influxdb:rw
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "influx", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    read_only: true
    tmpfs: /run:rw,noexec,nosuid,size=65536k

  fluentd:
    image: grafana/fluent-plugin-loki:latest
    ports:
      - 24224:24224
      - 24224:24224/udp
    volumes:
      - $LPI_DIR/fluentd:/fluentd/etc
    command: fluentd -c /fluentd/etc/fluent.conf
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs: /run:rw,noexec,nosuid,size=65536k

volumes:
  grafana-storage:
  prometheus-storage:
  loki-storage:
  influxdb-storage:
  loki-wal:

networks:
  default:
    driver: bridge
    ipam:
      config:
        - subnet: $LOKI_NETWORK_SUBNET
    driver_opts:
      com.docker.network.bridge.name: loki_network

secrets:
  grafana_password:
    external: true
  loki_password:
    external: true
EOL

# Create Prometheus configuration file
mkdir -p $LPI_DIR/prometheus
cat <<EOL > $LPI_DIR/prometheus/prometheus.yml
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

# Create Promtail configuration file
mkdir -p $LPI_DIR/promtail
cat <<EOL > $LPI_DIR/promtail/promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 9081

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
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

  - job_name: pfsense
    static_configs:
      - targets:
          - 0.0.0.0
        labels:
          job: pfsense
          __path__: /var/log/pfsense/*log
EOL

# Create Fluentd configuration file
mkdir -p $LPI_DIR/fluentd
cat <<EOL > $LPI_DIR/fluentd/fluent.conf
<source>
  @type syslog
  port 24224
  bind 0.0.0.0
  tag pfsense
  <parse>
    @type syslog
  </parse>
</source>

<filter pfsense.**>
  @type record_transformer
  enable_ruby
  <record>
    hostname \${hostname}
    tag \${tag}
  </record>
</filter>

<filter pfsense.**>
  @type parser
  key_name message
  <parse>
    @type regexp
    expression /^(?<time>[^ ]+ +[^ ]+) (?<host>[^ ]+) (?<program>[^ ]+): (?<message>.*)$/
    time_format %b %d %H:%M:%S
  </parse>
</filter>

<match pfsense.**>
  @type loki
  url http://loki:3100
  extra_labels {"job":"pfsense", "hostname":"\${hostname}"}
  flush_interval 5s
  flush_at_shutdown true
  buffer_chunk_limit 1m
  buffer_queue_limit 32
</match>
EOL

# Create rsyslog configuration file
sudo tee /etc/rsyslog.d/01-pfsense-to-fluentd.conf > /dev/null <<EOL
# Load necessary modules
module(load="imudp")
module(load="omfwd")

# Listen for UDP syslog messages on port 514
input(type="imudp" port="514")

# Forward all logs to Fluentd
*.* action(type="omfwd" target="127.0.0.1" port="24224" protocol="tcp" template="RSYSLOG_SyslogProtocol23Format")
EOL

# Restart rsyslog service
sudo systemctl restart rsyslog
sudo systemctl status rsyslog

# Create Loki configuration file
mkdir -p $LPI_DIR/loki
cat <<EOL > $LPI_DIR/loki/loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules

wal:
  dir: /wal

replication_factor: 1

ring:
  instance_addr: 127.0.0.1

schema_config:
  configs:
    - from: 2022-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

ruler:
  alertmanager_url: http://localhost:9093
  storage:
    type: local
    local:
      directory: /loki/rules

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  max_cache_freshness_per_query: 10m
  retention_period: 168h
EOL

# Set permissions for configuration files
sudo chown -R 10001:10001 $LPI_DIR/loki
sudo chmod 600 $LPI_DIR/loki/loki-config.yaml
sudo chown -R 65534:65534 $LPI_DIR/prometheus
sudo chmod 600 $LPI_DIR/prometheus/prometheus.yml
sudo chown -R 65534:65534 $LPI_DIR/promtail
sudo chmod 600 $LPI_DIR/promtail/promtail-config.yaml

# Create log extraction script
cat <<'EOL' > $LPI_DIR/extract_loki_logs.sh
#!/bin/bash

# Loki log extraction script

# Variables
output_dir="$LPI_DIR/loki-logs"
current_date=$(date +%Y-%m-%d)
output_file="$output_dir/loki-logs-$current_date.gz"

# Extract logs for the past week
docker exec loki loki-can-query --start=$(date -d '1 week ago' +%Y-%m-%d) --end=$(date +%Y-%m-%d) --output=json | gzip > $output_file

# Ensure the file has correct permissions
sudo chown 10001:10001 $output_file
sudo chmod 600 $output_file
EOL

# Make the script executable
chmod +x $LPI_DIR/extract_loki_logs.sh

# Setup cron job
(crontab -l 2>/dev/null; echo "0 6 * * 1 $LPI_DIR/extract_loki_logs.sh") | crontab -

# Start Docker containers
cd $LPI_DIR
docker compose up -d --verbose

# Display running containers
docker ps
