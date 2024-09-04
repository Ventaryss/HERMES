#!/bin/bash

# Fonction pour vérifier l'exécution des commandes
check_command() {
    if [ $? -ne 0 ]; then
        echo "Erreur : $1 a échoué." >&2
        exit 1
    fi
}

# Créer les répertoires nécessaires avec les permissions adéquates
mkdir -p ~/lpi-monitoring/loki-storage ~/lpi-monitoring/loki-wal
check_command "Création des répertoires loki-storage et loki-wal"
sudo chown -R $(whoami):$(whoami) ~/lpi-monitoring/loki-storage ~/lpi-monitoring/loki-wal
sudo chmod -R 777 ~/lpi-monitoring/loki-storage ~/lpi-monitoring/loki-wal

# Créer le répertoire de configuration Loki
mkdir -p ~/lpi-monitoring/configs/loki
check_command "Création du répertoire de configuration Loki"

# Créer un fichier de configuration Loki par défaut
cat <<EOL > ~/lpi-monitoring/configs/loki/loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9095

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_block_size: 262144
  chunk_retain_period: 1m
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2020-10-24
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
check_command "Création du fichier de configuration Loki"

# Utiliser le fichier docker-compose spécifique pour Loki
docker compose -f ~/lpi-monitoring/docker/docker-compose-loki.yml up -d
check_command "Démarrage de Loki avec Docker Compose"

# Configuration de Logrotate pour l'archivage des logs
LOGROTATE_CONF="/etc/logrotate.d/loki_logs"
sudo tee $LOGROTATE_CONF > /dev/null <<EOL
/var/log/loki/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    dateext
    dateformat _Semaine_%V
    olddir /path/to/Archives_Logs/loki_logs_archives/
    create 640 loki loki
    notifempty
    sharedscripts
    postrotate
        systemctl restart loki
    endscript
}
EOL
check_command "Configuration de Logrotate pour Loki"
