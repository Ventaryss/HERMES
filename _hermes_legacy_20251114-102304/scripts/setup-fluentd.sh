#!/bin/bash

# ===========================================
# HERMES - Configuration Fluentd
# ===========================================
# Script pour générer les fichiers de configuration Fluentd
# Peut être appelé indépendamment ou via le script principal

set -euo pipefail

# Définir le répertoire de base
BASE_DIR="${HOME}/HERMES"

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FLUENTD] $1"
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
generate_fluentd_config() {
    log "Génération de la configuration Fluentd..."
    
    # Créer le répertoire de configuration Fluentd
    mkdir -p "${BASE_DIR}/configs/fluentd"
    check_command "Création du répertoire de configuration Fluentd" || return 1
    
    # Créer le fichier de configuration Fluentd optimisé
    cat <<'EOL' > "${BASE_DIR}/configs/fluentd/fluent.conf"
# ===========================================
# Configuration Fluentd - Collecteur de logs flexible
# ===========================================
# Documentation: https://docs.fluentd.org/configuration

# === Sources d'entrée ===

# Entrée pour logs pfSense via TCP (port 24224)
<source>
  @type forward
  @id input_pfsense
  @label @pfsense
  port 24224
  bind 0.0.0.0
  tag pfsense
</source>

# Entrée pour logs Stormshield via TCP (port 24225)
<source>
  @type forward
  @id input_stormshield
  @label @stormshield
  port 24225
  bind 0.0.0.0
  tag stormshield
</source>

# Entrée pour logs Palo Alto via TCP (port 24226)
<source>
  @type forward
  @id input_paloalto
  @label @paloalto
  port 24226
  bind 0.0.0.0
  tag paloalto
</source>

# Entrée pour logs pfSense depuis fichiers
<source>
  @type tail
  @id input_pfsense_file
  @label @pfsense
  path /var/log/pfsense/*.log
  pos_file /fluentd/logs/pfsense.pos
  tag pfsense.file
  <parse>
    @type syslog
    message_format rfc3164
    with_priority false
  </parse>
</source>

# Entrée pour logs Stormshield depuis fichiers
<source>
  @type tail
  @id input_stormshield_file
  @label @stormshield
  path /var/log/stormshield/*.log
  pos_file /fluentd/logs/stormshield.pos
  tag stormshield.file
  <parse>
    @type syslog
    message_format auto
    with_priority false
  </parse>
</source>

# Entrée pour logs Palo Alto depuis fichiers
<source>
  @type tail
  @id input_paloalto_file
  @label @paloalto
  path /var/log/paloalto/*.log
  pos_file /fluentd/logs/paloalto.pos
  tag paloalto.file
  <parse>
    @type csv
    delimiter ","
    keys time_received,serial,type,threat,subtype,time_generated,src,dst,src_port,dst_port,protocol,action,rule,application,category,severity,direction,misc
  </parse>
</source>

# === Filtres et transformations ===

# Label pour traitement des logs pfSense
<label @pfsense>
  # Ajouter des métadonnées
  <filter **>
    @type record_transformer
    <record>
      firewall_type pfsense
      environment production
      timestamp ${time}
    </record>
  </filter>
  
  # Parser spécifique pour extraire les informations de firewall
  <filter **>
    @type parser
    key_name message
    reserve_data true
    <parse>
      @type regexp
      expression /^.+rule\s+(?<rule_id>\d+).+\s(?<action>\w+)\s+(?<protocol>\w+)\s+from\s+(?<src_ip>[\d\.]+):(?<src_port>\d+)\s+to\s+(?<dst_ip>[\d\.]+):(?<dst_port>\d+)/
    </parse>
  </filter>
  
  # Envoyer vers Loki
  <match **>
    @type loki
    @id output_loki_pfsense
    url "#{ENV['LOKI_URL'] || 'http://loki:3100'}"
    flush_interval 10s
    flush_at_shutdown true
    buffer_chunk_limit 1m
    <label>
      job pfsense
      firewall pfsense
    </label>
  </match>
</label>

# Label pour traitement des logs Stormshield
<label @stormshield>
  # Ajouter des métadonnées
  <filter **>
    @type record_transformer
    <record>
      firewall_type stormshield
      environment production
      timestamp ${time}
    </record>
  </filter>
  
  # Envoyer vers Loki
  <match **>
    @type loki
    @id output_loki_stormshield
    url "#{ENV['LOKI_URL'] || 'http://loki:3100'}"
    flush_interval 10s
    flush_at_shutdown true
    buffer_chunk_limit 1m
    <label>
      job stormshield
      firewall stormshield
    </label>
  </match>
</label>

# Label pour traitement des logs Palo Alto
<label @paloalto>
  # Ajouter des métadonnées
  <filter **>
    @type record_transformer
    <record>
      firewall_type paloalto
      environment production
      timestamp ${time}
    </record>
  </filter>
  
  # Envoyer vers Loki
  <match **>
    @type loki
    @id output_loki_paloalto
    url "#{ENV['LOKI_URL'] || 'http://loki:3100'}"
    flush_interval 10s
    flush_at_shutdown true
    buffer_chunk_limit 1m
    <label>
      job paloalto
      firewall paloalto
    </label>
  </match>
</label>

# === Configuration du buffer ===
<system>
  log_level info
  suppress_repeated_stacktrace true
  emit_error_log_interval 30s
  suppress_config_dump true
</system>
EOL
    check_command "Création du fichier de configuration Fluentd" || return 1
    
    log "Configuration Fluentd générée avec succès"
    return 0
}

# Exécuter la fonction si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${1:-}" == "config_only" ]]; then
    generate_fluentd_config
fi
