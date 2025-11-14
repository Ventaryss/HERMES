#!/bin/bash

# ===========================================
# HERMES - Configuration Loki
# ===========================================
# Script pour générer les fichiers de configuration Loki
# Peut être appelé indépendamment ou via le script principal

set -euo pipefail

# Définir le répertoire de base
BASE_DIR="${HOME}/HERMES"

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [LOKI] $1"
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
generate_loki_config() {
    log "Génération de la configuration Loki..."
    
    # Créer le répertoire de configuration Loki
    mkdir -p "${BASE_DIR}/configs/loki"
    check_command "Création du répertoire de configuration Loki" || return 1
    
    # Créer le fichier de configuration Loki optimisé
    cat <<'EOL' > "${BASE_DIR}/configs/loki/loki-config.yaml"
# ===========================================
# Configuration Loki - Agrégation de logs
# ===========================================
# Documentation: https://grafana.com/docs/loki/latest/configuration/

# Désactiver l'authentification pour un usage interne
auth_enabled: false

# Configuration du serveur HTTP/gRPC
server:
  http_listen_port: 3100
  grpc_listen_port: 9095
  # Limite de taille pour les requêtes HTTP
  http_server_read_timeout: 600s
  http_server_write_timeout: 600s
  grpc_server_max_recv_msg_size: 104857600  # 100 MB
  grpc_server_max_send_msg_size: 104857600  # 100 MB

# Configuration de l'ingester (composant qui écrit les logs)
ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  # Période avant qu'un chunk inactif soit flushé
  chunk_idle_period: 5m
  # Période maximale avant qu'un chunk soit flushé
  chunk_retain_period: 30s
  # Taille maximale d'un chunk
  chunk_block_size: 262144
  # Tentatives de transfert
  max_transfer_retries: 0
  # Durée de vie du WAL (Write-Ahead Log)
  wal:
    enabled: true
    dir: /wal
    replay_memory_ceiling: 1GB

# Configuration du schéma de stockage
schema_config:
  configs:
    # Utilisation du schéma v11 (recommandé)
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

# Configuration du stockage
storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  
  filesystem:
    directory: /loki/chunks

# Configuration des limites
limits_config:
  # Ne pas forcer le nom de métrique
  enforce_metric_name: false
  # Rejeter les anciens échantillons (plus de 7 jours)
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  # Limites d'ingestion
  ingestion_rate_mb: 10
  ingestion_burst_size_mb: 20
  # Limite de taille par requête
  max_entries_limit_per_query: 5000
  max_streams_per_user: 0
  max_global_streams_per_user: 0
  # Rétention des données
  retention_period: 720h  # 30 jours

# Configuration du compacteur (nettoyage et optimisation)
compactor:
  working_directory: /loki/compactor
  shared_store: filesystem
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150

# Configuration du chunk store
chunk_store_config:
  max_look_back_period: 0s
  chunk_cache_config:
    enable_fifocache: true
    default_validity: 24h

# Configuration du query frontend (cache des requêtes)
query_range:
  results_cache:
    cache:
      enable_fifocache: true
      default_validity: 24h
  cache_results: true
  max_retries: 5
  parallelise_shardable_queries: true

# Configuration de la table manager (deprecated mais encore utilisé en v11)
table_manager:
  retention_deletes_enabled: true
  retention_period: 720h  # 30 jours
EOL
    check_command "Création du fichier de configuration Loki" || return 1
    
    log "Configuration Loki générée avec succès"
    return 0
}

# Exécuter la fonction si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$1" == "config_only" ]]; then
    generate_loki_config
fi
