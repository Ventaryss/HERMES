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
  @type record_transformer
  enable_ruby
  <record>
    hostname \${hostname}
  </record>
</filter>

# Filtre pour pfSense
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

  <match **>
    @type null
  </match>
</label>

# Filtre pour les logs clients, hors pfSense et localhost
<filter syslog.**>
  @type grep
  <regexp>
    key hostname
    pattern /^((?!pfSense).)*$/
  </regexp>
</filter>

<filter syslog.**>
  @type grep
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

# Filtre pour Stormshield
<source>
  @type syslog
  port 24225
  bind 0.0.0.0
  tag stormshield
</source>

<filter stormshield.**>
  @type parser
  format syslog
  time_format %b %d %H:%M:%S
  key_name message
</filter>

<match stormshield.**>
  @type loki
  url http://loki:3100
  extra_labels {"job":"stormshield"}
  flush_interval 5s
  flush_at_shutdown true
  buffer_chunk_limit 1m
  buffer_queue_limit 32
</match>

# Filtre pour Palo Alto
<source>
  @type syslog
  port 24226
  bind 0.0.0.0
  tag paloalto
</source>

<filter paloalto.**>
  @type parser
  format syslog
  time_format %b %d %H:%M:%S
  key_name message
</filter>

<match paloalto.**>
  @type loki
  url http://loki:3100
  extra_labels {"job":"paloalto"}
  flush_interval 5s
  flush_at_shutdown true
  buffer_chunk_limit 1m
  buffer_queue_limit 32
</match>
EOL

# Use the specific docker-compose file for Fluentd
docker compose -f ~/lpi-monitoring/docker/docker-compose-fluentd.yml up -d
