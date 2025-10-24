#!/bin/bash

# ===========================================
# HERMES - Configuration Promtail
# ===========================================
# Script pour générer les fichiers de configuration Promtail
# Peut être appelé indépendamment ou via le script principal

set -euo pipefail

# Définir le répertoire de base
BASE_DIR="${HOME}/HERMES"

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PROMTAIL] $1"
}

# Fonction pour vérifier l'exécution des commandes
check_command() {
    if [[ $? -ne 0 ]]; then
        log "Erreur : $1 a échoué."
        return 1
    fi
    return 0
}

# Fonction principale pour générer la configuration
generate_promtail_config() {
    log "Génération de la configuration Promtail..."
    
    # Créer le répertoire de configuration Promtail
    mkdir -p "${BASE_DIR}/configs/promtail"
    check_command "Création du répertoire de configuration Promtail" || return 1
    
    # Créer le fichier de configuration Promtail optimisé
    cat <<'EOL' > "${BASE_DIR}/configs/promtail/promtail-config.yaml"
# ===========================================
# Configuration Promtail - Collecteur de logs pour Loki
# ===========================================
# Documentation: https://grafana.com/docs/loki/latest/clients/promtail/configuration/

# Configuration du serveur HTTP/gRPC
server:
  http_listen_port: 9080
  grpc_listen_port: 9081
  log_level: info

# Fichier de positions pour suivre l'avancement de la lecture
positions:
  filename: /tmp/positions.yaml

# Configuration des clients Loki
clients:
  - url: http://loki:3100/loki/api/v1/push
    batchwait: 1s
    batchsize: 1048576  # 1MB
    timeout: 10s
    backoff_config:
      min_period: 500ms
      max_period: 5m
      max_retries: 10
    # Limites de requêtes
    external_labels:
      cluster: 'hermes'

# Configuration des collecteurs de logs
scrape_configs:
  # === Logs système généraux ===
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: system
          host: ${HOSTNAME:-localhost}
          __path__: /var/log/*.log
    pipeline_stages:
      # Parser syslog standard
      - regex:
          expression: '^(?P<timestamp>\w+\s+\d+\s+\d{2}:\d{2}:\d{2})\s+(?P<hostname>\S+)\s+(?P<service>\S+)(\[(?P<pid>\d+)\])?:\s+(?P<message>.*)$'
      - timestamp:
          source: timestamp
          format: 'Jan _2 15:04:05'
      - labels:
          hostname:
          service:

  # === Logs pfSense ===
  - job_name: pfsense
    static_configs:
      - targets:
          - localhost
        labels:
          job: pfsense
          firewall: pfsense
          __path__: /var/log/pfsense/*.log
    pipeline_stages:
      # Parser pour logs pfSense
      - regex:
          expression: '^(?P<timestamp>\w+\s+\d+\s+\d{2}:\d{2}:\d{2})\s+(?P<host>[^\s]+)\s+(?P<program>[^\[]+)\[(?P<pid>\d+)\]:\s+(?P<message>.*)$'
      - timestamp:
          source: timestamp
          format: 'Jan _2 15:04:05'
      # Extraction des règles de firewall
      - regex:
          expression: 'rule\s+(?P<rule_number>\d+).+?(?P<action>\w+)\s+(?P<protocol>\w+)\s+from\s+(?P<src_ip>[^\s]+)\s+to\s+(?P<dst_ip>[^\s]+)\s+dst-port\s+(?P<dst_port>\d+)'
          source: message
      - labels:
          action:
          protocol:
          src_ip:
          dst_ip:
          rule_number:

  # === Logs Stormshield ===
  - job_name: stormshield
    static_configs:
      - targets:
          - localhost
        labels:
          job: stormshield
          firewall: stormshield
          __path__: /var/log/stormshield/*.log
    pipeline_stages:
      - regex:
          expression: '^(?P<timestamp>[^\s]+\s+[^\s]+)\s+(?P<hostname>\S+)\s+(?P<message>.*)$'
      - labels:
          hostname:

  # === Logs Palo Alto ===
  - job_name: paloalto
    static_configs:
      - targets:
          - localhost
        labels:
          job: paloalto
          firewall: paloalto
          __path__: /var/log/paloalto/*.log
    pipeline_stages:
      - regex:
          expression: '^(?P<timestamp>[^\s]+\s+[^\s]+)\s+(?P<hostname>\S+)\s+(?P<message>.*)$'
      - labels:
          hostname:

  # === Logs clients ===
  - job_name: client_logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: client_logs
          log_type: client
          __path__: /var/log/client_logs/*.log
    pipeline_stages:
      - json:
          expressions:
            time: Time
            host: Host
            program: Program
            message: message
      - timestamp:
          source: time
          format: RFC3339
      - labels:
          host:
          program:

  # === Logs Grafana (via montage Docker) ===
  # Note: Ces logs sont dans le conteneur, pas sur l'hôte
  # - job_name: grafana
  #   static_configs:
  #     - targets:
  #         - localhost
  #       labels:
  #         job: grafana
  #         service: visualization
  #         __path__: /var/log/grafana/*.log

  # === Logs des conteneurs Docker ===
  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*.log
    pipeline_stages:
      # Parser pour logs JSON de Docker
      - json:
          expressions:
            output: log
            stream: stream
            time: time
      - timestamp:
          source: time
          format: RFC3339Nano
      - labels:
          stream:
      - output:
          source: output

# Limites de fichiers cibles
target_config:
  sync_period: 10s
EOL
    check_command "Création du fichier de configuration Promtail" || return 1
    
    log "Configuration Promtail générée avec succès"
    return 0
}

# Exécuter la fonction si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${1:-}" == "config_only" ]]; then
    generate_promtail_config
fi
