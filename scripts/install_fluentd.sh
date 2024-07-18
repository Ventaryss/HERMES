#!/bin/bash

# Créer le répertoire de configuration Fluentd
mkdir -p ~/LPI/configs/fluentd

# Créer le fichier de configuration Fluentd
cat <<EOL > ~/LPI/configs/fluentd/fluent.conf
<source>
  @type syslog
  port 24224
  bind 0.0.0.0
  tag syslog
</source>

<filter syslog.**>
  @type grep
  <regexp>
    key message
    pattern /pfSense\.home\.arpa/
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

  <filter **>
    @type parser
    key_name message
    <parse>
      @type regexp
      expression /^(?<time>\w+\s+\d+\s+\d{2}:\d{2}:\d{2})\s+(?<host>[^\s]+)\s+(?<program>[^\[]+)\[(?<pid>\d+)\]:\s+(?<id>\d+),,,(?<sub_rule>\d+),(?<anchor>\w+),(?<tracker>\w+),(?<interface>\w+),(?<reason>\w+),(?<action>\w+),(?<direction>\w+),(?<ip_version>[^,]+),(?<protocol>\w+),(?<protocol_id>\d+),(?<length>\d+),(?<src_ip>[^,]+),(?<dst_ip>[^,]+),(?<src_port>\d+),(?<dst_port>\d+)/
      time_format %b %d %H:%M:%S
    </parse>
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
EOL

# Use the specific docker-compose file for Fluentd
docker compose -f ~/lpi-monitoring/docker/docker-compose-fluentd.yml up -d
