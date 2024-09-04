#!/bin/bash

# Fonction pour vérifier l'exécution des commandes
check_command() {
    if [ $? -ne 0 ]; then
        echo "Erreur : $1 a échoué." >&2
        exit 1
    fi
}

# Créer le répertoire de configuration Fluentd
mkdir -p ~/lpi-monitoring/configs/fluentd
check_command "Création du répertoire de configuration Fluentd"

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

# Filtre pour les logs autres que pfSense et localhost
<filter syslog.**>
  @type grep
  <regexp>
    key hostname
    pattern /^((?!pfSense|127.0.0.1).)*$/
  </regexp>
</filter>

<match syslog.**>
  @type relabel
  @label @other_logs
</match>

<label @other_logs>
  <filter **>
    @type record_transformer
    <record>
      job other_logs
    </record>
  </filter>

  <match **>
    @type loki
    url http://loki:3100
    extra_labels {"job":"other_logs"}
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
check_command "Création du fichier de configuration Fluentd"

# Utiliser le fichier docker-compose spécifique pour Fluentd
docker compose -f ~/lpi-monitoring/docker/docker-compose-fluentd.yml up -d
check_command "Démarrage de Fluentd avec Docker Compose"

# Configuration de Logrotate pour l'archivage des logs
LOGROTATE_CONF="/etc/logrotate.d/fluentd_logs"
sudo tee $LOGROTATE_CONF > /dev/null <<EOL
/var/log/fluentd/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    dateext
    dateformat _Semaine_%V
    olddir /path/to/Archives_Logs/fluentd_logs_archives/
    create 640 root adm
    notifempty
    sharedscripts
    postrotate
        systemctl restart docker
    endscript
}
EOL
check_command "Configuration de Logrotate pour Fluentd"
