#!/bin/bash

# ===========================================
# HERMES - Configuration Grafana
# ===========================================
# Script pour générer les fichiers de provisioning Grafana
# Datasources et dashboards

set -euo pipefail

# Définir le répertoire de base
BASE_DIR="${HOME}/HERMES"

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GRAFANA] $1"
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
generate_grafana_config() {
    log "Génération de la configuration Grafana..."
    
    # Créer les répertoires de provisioning
    mkdir -p "${BASE_DIR}/configs/grafana/provisioning"/{dashboards,datasources,notifiers,plugins}
    check_command "Création des répertoires de provisioning" || return 1
    
    # === Fichier de provisioning des dashboards ===
    cat <<'EOL' > "${BASE_DIR}/configs/grafana/provisioning/dashboards/default.yaml"
# ===========================================
# Grafana - Provisioning des Dashboards
# ===========================================
apiVersion: 1

providers:
  # Provider par défaut pour les dashboards de monitoring
  - name: 'HERMES'
    orgId: 1
    folder: 'HERMES'
    folderUid: 'hermes'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: true
EOL
    check_command "Création du fichier de provisioning des dashboards" || return 1
    
    # === Fichier de provisioning des datasources ===
    # Note: Le token InfluxDB sera généré au premier démarrage
    cat <<'EOL' > "${BASE_DIR}/configs/grafana/provisioning/datasources/default.yaml"
# ===========================================
# Grafana - Provisioning des Datasources
# ===========================================
apiVersion: 1

# Supprimer les datasources non définies
deleteDatasources:
  - name: TestData DB
    orgId: 1

datasources:
  # === Prometheus - Métriques ===
  - name: Prometheus
    type: prometheus
    access: proxy
    uid: prometheus
    orgId: 1
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      httpMethod: POST
      timeInterval: "15s"
      queryTimeout: "60s"
      # Options de cache
      incrementalQuerying: true
      incrementalQueryOverlapWindow: "10m"
    version: 1

  # === Loki - Logs ===
  - name: Loki
    type: loki
    access: proxy
    uid: loki
    orgId: 1
    url: http://loki:3100
    editable: true
    jsonData:
      maxLines: 1000
      derivedFields:
        # Extraction automatique de traceID si présent
        - datasourceUid: tempo
          matcherRegex: "traceID=(\\w+)"
          name: TraceID
          url: "$${__value.raw}"
    version: 1

  # === InfluxDB - Métriques time-series ===
  # Note: Vous devrez mettre à jour le token après la première installation
  - name: InfluxDB
    type: influxdb
    access: proxy
    uid: influxdb
    orgId: 1
    url: http://influxdb:8086
    editable: true
    jsonData:
      version: Flux
      organization: hermes
      defaultBucket: logs
      tlsSkipVerify: true
    # Vous devrez définir le token manuellement ou via variables d'environnement
    # secureJsonData:
    #   token: "YOUR_INFLUXDB_TOKEN_HERE"
    version: 1
EOL
    check_command "Création du fichier de provisioning des datasources" || return 1
    
    # === Fichier de configuration de plugins (optionnel) ===
    cat <<'EOL' > "${BASE_DIR}/configs/grafana/provisioning/plugins/default.yaml"
# ===========================================
# Grafana - Configuration des Plugins
# ===========================================
apiVersion: 1

# Liste des plugins à installer automatiquement
apps:
  # Ajouter ici les plugins nécessaires
  # Exemple:
  # - name: grafana-clock-panel
  #   version: 2.1.0
EOL
    check_command "Création du fichier de configuration des plugins" || return 1
    
    # Copier les dashboards existants s'ils sont présents
    if [[ -d "${SCRIPT_DIR:-$(dirname $0)/..}/dashboards_grafana" ]]; then
        log "Copie des dashboards prédéfinis..."
        mkdir -p "${BASE_DIR}/dashboards_grafana"
        # Copier tous les fichiers JSON
        find "${SCRIPT_DIR:-$(dirname $0)/..}/dashboards_grafana" -name "*.json" \
            -exec cp {} "${BASE_DIR}/dashboards_grafana/" \; 2>/dev/null || true
    fi
    
    # Créer un dashboard d'exemple si aucun n'existe
    if [[ ! -f "${BASE_DIR}/dashboards_grafana/system-overview.json" ]]; then
        log "Création d'un dashboard d'exemple..."
        cat <<'EOL' > "${BASE_DIR}/dashboards_grafana/system-overview.json"
{
  "dashboard": {
    "title": "HERMES - System Overview",
    "tags": ["hermes", "system", "overview"],
    "timezone": "browser",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
          }
        ]
      }
    ],
    "schemaVersion": 16,
    "version": 0
  }
}
EOL
    fi
    
    log "Configuration Grafana générée avec succès"
    log "N'oubliez pas de définir le token InfluxDB dans le fichier datasources après l'installation!"
    return 0
}

# Exécuter la fonction si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${1:-}" == "config_only" ]]; then
    generate_grafana_config
fi
