#!/bin/bash

# Stop and remove existing Docker containers if they exist
containers=$(docker ps -a -q --filter "name=loki" --filter "name=prometheus" --filter "name=grafana" --filter "name=influxdb" --filter "name=fluentd" --filter "name=promtail")
if [ -n "$containers" ]; then
    docker stop $containers
    docker rm $containers
else
    echo "No existing containers to stop or remove."
fi

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
mkdir -p ~/LPI/promtail ~/LPI/prometheus ~/LPI/loki ~/LPI/loki-wal ~/LPI/loki-logs ~/LPI/fluentd ~/LPI/pfsense-logs

# Set permissions for Loki WAL directory
sudo chown -R 10001:10001 ~/LPI/loki-wal

# Create docker-compose.yml
cat <<EOL > ~/LPI/docker-compose.yml
version: '3'

services:
  grafana:
    image: grafana/grafana
    ports:
      - 3000:3000
    volumes:
      - grafana-storage:/var/lib/grafana

  prometheus:
    image: prom/prometheus
    ports:
      - 9090:9090
    volumes:
      - prometheus-storage:/prometheus
      - ~/LPI/prometheus:/etc/prometheus

  loki:
    image: grafana/loki
    ports:
      - "3100:3100"
    volumes:
      - loki-storage:/loki
      - ~/LPI/loki:/etc/loki
      - ~/LPI/loki-wal:/wal
    command: -config.file=/etc/loki/loki-config.yaml

  promtail:
    image: grafana/promtail
    volumes:
      - ~/LPI/promtail:/etc/promtail
      - /var/log:/var/log
    command: -config.file=/etc/promtail/promtail-config.yaml

  influxdb:
    image: influxdb
    ports:
      - 8086:8086
    volumes:
      - influxdb-storage:/var/lib/influxdb

  fluentd:
    image: grafana/fluent-plugin-loki:latest
    ports:
      - 24224:24224
      - 24224:24224/udp
    volumes:
      - ~/LPI/fluentd:/fluentd/etc
    command: fluentd -c /fluentd/etc/fluent.conf
    
volumes:
  grafana-storage:
  prometheus-storage:
  loki-storage:
  influxdb-storage:
  loki-wal:
EOL

# Create Prometheus configuration file
mkdir -p ~/LPI/prometheus
cat <<EOL > ~/LPI/prometheus/prometheus.yml
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
mkdir -p ~/LPI/promtail
cat <<EOL > ~/LPI/promtail/promtail-config.yaml
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
          - 10.0.200.250
        labels:
          job: pfsense
          __path__: /var/log/pfsense/*log
EOL

# Create Fluentd configuration file
mkdir -p ~/LPI/fluentd
cat <<EOL > ~/LPI/fluentd/fluent.conf
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
mkdir -p ~/LPI/loki
cat <<EOL > ~/LPI/loki/loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2020-05-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
    directory: /loki/index

  filesystem:
    directory: /loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
EOL

# Adjust permissions for configuration files
sudo chown $(whoami):$(whoami) ~/LPI/prometheus/prometheus.yml
sudo chown $(whoami):$(whoami) ~/LPI/promtail/promtail-config.yaml
sudo chown $(whoami):$(whoami) ~/LPI/fluentd/fluent.conf
sudo chown $(whoami):$(whoami) ~/LPI/loki/loki-config.yaml

# Create log extraction script
cat <<'EOL' > ~/LPI/extract_loki_logs.sh
#!/bin/bash

LOG_DIR=~/LPI/loki-logs
CURRENT_DATE=$(date +%Y-%m-%d)
LAST_MONDAY=$(date -d "last-monday" +%Y-%m-%d)
PREVIOUS_MONDAY=$(date -d "last-monday -7 days" +%Y-%m-%d)

mkdir -p $LOG_DIR

docker run --rm -v ~/LPI/loki-config.yaml:/etc/loki/local-config.yaml grafana/loki:latest \
  -config.file=/etc/loki/local-config.yaml query "{job=\"pfsense\"}" --since=$PREVIOUS_MONDAY --until=$LAST_MONDAY > $LOG_DIR/pfsense_logs_$PREVIOUS_MONDAY\_to_$LAST_MONDAY.log
EOL

# Make the script executable
chmod +x ~/LPI/extract_loki_logs.sh

# Setup cron job
(crontab -l 2>/dev/null; echo "0 6 * * 1 ~/LPI/extract_loki_logs.sh") | crontab -

# Start Docker containers
cd ~/LPI
docker compose up -d
docker ps
