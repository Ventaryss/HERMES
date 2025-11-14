#!/bin/bash

# ===========================================
# HERMES - Configuration Prometheus
# ===========================================
# Script pour générer les fichiers de configuration Prometheus
# Peut être appelé indépendamment ou via le script principal

set -euo pipefail

# Définir le répertoire de base
BASE_DIR="${HOME}/HERMES"

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PROMETHEUS] $1"
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
generate_prometheus_config() {
    log "Génération de la configuration Prometheus..."
    
    # Créer le répertoire de configuration Prometheus
    mkdir -p "${BASE_DIR}/configs/prometheus"
    check_command "Création du répertoire de configuration Prometheus" || return 1
    
    # Créer le fichier de configuration Prometheus optimisé
    cat <<'EOL' > "${BASE_DIR}/configs/prometheus/prometheus.yml"
# ===========================================
# Configuration Prometheus - Collecte de métriques
# ===========================================
# Documentation: https://prometheus.io/docs/prometheus/latest/configuration/configuration/

# Configuration globale
global:
  # Intervalle de collecte des métriques
  scrape_interval: 15s
  # Intervalle d'évaluation des règles d'alerte
  evaluation_interval: 15s
  # Timeout pour les requêtes de collecte
  scrape_timeout: 10s
  # Labels externes appliqués à toutes les métriques
  external_labels:
    monitor: 'hermes'
    environment: 'production'

# Configuration des alertes (optionnel)
alerting:
  alertmanagers:
    - static_configs:
        - targets: []
          # - 'alertmanager:9093'  # Décommenter si vous utilisez Alertmanager

# Fichiers de règles d'alerte (optionnel)
rule_files:
  # - "alerts/*.yml"
  # - "rules/*.yml"

# Configuration des cibles à scraper
scrape_configs:
  # === Surveillance de Prometheus lui-même ===
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: 'prometheus-server'
          service: 'monitoring'
    # Métriques à conserver
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'prometheus_.*'
        action: keep

  # === Node Exporter - Métriques système ===
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
        labels:
          instance: 'monitoring-server'
          service: 'system'
    # Collecte complète des métriques système
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'node_.*'
        action: keep

  # === InfluxDB - Métriques de base de données ===
  - job_name: 'influxdb'
    static_configs:
      - targets: ['influxdb:8086']
        labels:
          instance: 'influxdb-server'
          service: 'database'
    scrape_interval: 30s

  # === Grafana - Métriques d'application ===
  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']
        labels:
          instance: 'grafana-server'
          service: 'visualization'
    scrape_interval: 30s

  # === Loki - Métriques d'agrégation de logs ===
  - job_name: 'loki'
    static_configs:
      - targets: ['loki:3100']
        labels:
          instance: 'loki-server'
          service: 'logs'
    scrape_interval: 30s
    # Métriques importantes de Loki
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'loki_(ingester|distributor)_.*'
        action: keep

  # === Promtail - Métriques de collecte de logs ===
  - job_name: 'promtail'
    static_configs:
      - targets: ['promtail:9080']
        labels:
          instance: 'promtail-agent'
          service: 'log-collector'
    scrape_interval: 30s

  # === Docker - Métriques des conteneurs (optionnel) ===
  # Décommenter si vous voulez surveiller Docker
  # - job_name: 'docker'
  #   static_configs:
  #     - targets: ['host.docker.internal:9323']
  #       labels:
  #         instance: 'docker-engine'
  #         service: 'container-runtime'

  # === Clients externes - Ajoutez vos cibles ici ===
  # Exemple pour des node exporters externes:
  # - job_name: 'external-nodes'
  #   static_configs:
  #     - targets:
  #         - '192.168.1.10:9100'
  #         - '192.168.1.11:9100'
  #       labels:
  #         environment: 'production'
  #         region: 'datacenter-1'

# Configuration du stockage distant (optionnel)
# remote_write:
#   - url: "http://remote-storage:9090/api/v1/write"
#     queue_config:
#       capacity: 10000
#       max_shards: 50
#       max_samples_per_send: 500

# remote_read:
#   - url: "http://remote-storage:9090/api/v1/read"
EOL
    check_command "Création du fichier de configuration Prometheus" || return 1
    
    # Créer un fichier d'exemple de règles d'alerte
    mkdir -p "${BASE_DIR}/configs/prometheus/alerts"
    cat <<'EOL' > "${BASE_DIR}/configs/prometheus/alerts/example_alerts.yml"
# ===========================================
# Exemples de règles d'alerte Prometheus
# ===========================================
# Décommenter et adapter selon vos besoins

groups:
  - name: system_alerts
    interval: 30s
    rules:
      # Alerte si l'utilisation du CPU dépasse 80%
      # - alert: HighCPUUsage
      #   expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      #   for: 5m
      #   labels:
      #     severity: warning
      #   annotations:
      #     summary: "CPU usage is above 80% on {{ $labels.instance }}"
      #     description: "CPU usage is {{ $value }}% on {{ $labels.instance }}"
      
      # Alerte si la mémoire disponible est inférieure à 10%
      # - alert: LowMemory
      #   expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 < 10
      #   for: 5m
      #   labels:
      #     severity: critical
      #   annotations:
      #     summary: "Low memory on {{ $labels.instance }}"
      #     description: "Available memory is {{ $value }}% on {{ $labels.instance }}"
      
      # Alerte si l'espace disque disponible est inférieur à 10%
      # - alert: LowDiskSpace
      #   expr: (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}) * 100 < 10
      #   for: 5m
      #   labels:
      #     severity: warning
      #   annotations:
      #     summary: "Low disk space on {{ $labels.instance }}"
      #     description: "Available disk space is {{ $value }}% on {{ $labels.instance }} ({{ $labels.mountpoint }})"

  - name: service_alerts
    interval: 30s
    rules:
      # Alerte si un service est down
      # - alert: ServiceDown
      #   expr: up == 0
      #   for: 2m
      #   labels:
      #     severity: critical
      #   annotations:
      #     summary: "Service {{ $labels.job }} is down"
      #     description: "{{ $labels.job }} on {{ $labels.instance }} has been down for more than 2 minutes"
EOL
    check_command "Création du fichier d'exemples d'alertes" || return 1
    
    log "Configuration Prometheus générée avec succès"
    return 0
}

# Exécuter la fonction si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${1:-}" == "config_only" ]]; then
    generate_prometheus_config
fi
