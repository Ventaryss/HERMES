#!/bin/bash

# Créer le répertoire de configuration Fluentd
mkdir -p ~/lpi-monitoring/configs/fluentd

# Créer le fichier de configuration Fluentd
cat <<EOL > ~/lpi-monitoring/configs/fluentd/fluent.conf
<source>
  @type syslog
  port 24224
  bind 0.0.0.0
  tag syslog
</source>

<filter syslog.**>
  @type grep
  <regexp>
    key hostname
    pattern /pfSense/
  </regexp>
</filter>

<match syslog.**>
  @type relabel
  @label @pfsense
</match>

<label @pfsense>
  <filter **>
    @type record_transformer
    <record>
      job pfsense
    </record>
  </filter>

  <match **>
    @type loki
    url http://loki:3100
    extra_labels {"job":"pfsense"}
    flush_interval 5s
    flush_at_shutdown true
    buffer_chunk_limit 1m
    buffer_queue_limit 32
  </match>
</label>

<filter syslog.**>
  @type grep
  <regexp>
    key hostname
    pattern /^((?!pfSense).)*$/
  </regexp>
  <regexp>
    key hostname
    pattern /^((?!127.0.0.1).)*$/
  </regexp>
</filter>

<match syslog.**>
  @type relabel
  @label @clients
</match>

<label @clients>
  <filter **>
    @type record_transformer
    <record>
      job clients_clients
    </record>
  </filter>

  <match **>
    @type loki
    url http://loki:3100
    extra_labels {"job":"clients_clients"}
    flush_interval 5s
    flush_at_shutdown true
    buffer_chunk_limit 1m
    buffer_queue_limit 32
  </match>
</label>
EOL

# Use the specific docker-compose file for Fluentd
docker compose -f ~/lpi-monitoring/docker/docker-compose-fluentd.yml up -d
