#!/bin/bash
# Module sources - Gestion des sources de logs HERMES v3

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
SOURCES_CONFIG="${HERMES_BASE_DIR}/config/sources.json"
COMPOSE_CMD="${COMPOSE_CMD:-}"

sources_init_compose_cmd() {
  if [[ -n "${COMPOSE_CMD:-}" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "docker-compose introuvable."
    exit 1
  fi
}

# Initialiser le fichier sources s'il n'existe pas
sources_init() {
  if [[ ! -f "$SOURCES_CONFIG" ]]; then
    cat > "$SOURCES_CONFIG" <<'EOF'
{
  "sources": [],
  "version": "1.0"
}
EOF
    info "Fichier sources.json initialisé"
  fi
}

# Lister les sources configurées
sources_list() {
  section_title "Sources de logs configurées"
  
  sources_init
  
  if ! command -v jq >/dev/null 2>&1; then
    warning "jq non installé, affichage brut du JSON"
    cat "$SOURCES_CONFIG"
    return 0
  fi
  
  local count=$(jq '.sources | length' "$SOURCES_CONFIG")
  
  if [[ "$count" -eq 0 ]]; then
    info "Aucune source configurée pour le moment"
    echo
    echo -e "${DIM}Utilisez l'option 'Ajouter une source' pour configurer vos sources de logs${NC}"
    return 0
  fi
  
  echo -e "${BOLD}Total: ${WHITE}${count}${NC} source(s)"
  echo
  
  jq -r '.sources[] | "[\(.id)] \(.name) - \(.type)
  • Host: \(.host):\(.port)
  • Format: \(.format)
  • Activé: \(.enabled)"' "$SOURCES_CONFIG" | while IFS= read -r line; do
    if [[ "$line" =~ ^\[.*\] ]]; then
      echo -e "${CYAN}${line}${NC}"
    else
      echo -e "${DIM}${line}${NC}"
    fi
  done
}

# Ajouter une nouvelle source
sources_add() {
  section_title "Ajout d'une source de logs"
  
  sources_init
  
  echo -e "${CYAN}Types de sources disponibles :${NC}"
  echo -e "  ${WHITE}1${NC} - Firewall (pfSense, Palo Alto, Stormshield...)"
  echo -e "  ${WHITE}2${NC} - Serveur Linux (rsyslog)"
  echo -e "  ${WHITE}3${NC} - Application (fichiers de logs)"
  echo -e "  ${WHITE}4${NC} - Conteneur Docker"
  echo -e "  ${WHITE}5${NC} - Source personnalisée"
  echo
  
  read -r -p "$(echo -e ${CYAN}Type de source [1-5]: ${NC})" source_type
  echo
  
  case "$source_type" in
    1) _sources_add_firewall ;;
    2) _sources_add_linux ;;
    3) _sources_add_application ;;
    4) _sources_add_docker ;;
    5) _sources_add_custom ;;
    *) error "Type invalide"; return 1 ;;
  esac
}

# Ajouter un firewall
_sources_add_firewall() {
  echo -e "${CYAN}${BOLD}═══ Configuration Firewall ═══${NC}"
  echo
  
  read -r -p "Nom de la source (ex: pfsense-paris): " name
  read -r -p "Adresse IP du firewall: " host
  read -r -p "Port d'écoute (défaut 514): " port
  port=${port:-514}
  
  echo
  echo -e "${CYAN}Type de firewall :${NC}"
  echo -e "  ${WHITE}1${NC} - pfSense"
  echo -e "  ${WHITE}2${NC} - Palo Alto"
  echo -e "  ${WHITE}3${NC} - Stormshield"
  echo -e "  ${WHITE}4${NC} - Fortinet FortiGate"
  echo -e "  ${WHITE}5${NC} - Cisco ASA"
  echo -e "  ${WHITE}6${NC} - Autre (format personnalisé)"
  echo
  read -r -p "Type [1-6]: " fw_type
  
  case "$fw_type" in
    1) format="syslog_pfsense" ;;
    2) format="syslog_paloalto" ;;
    3) format="syslog_stormshield" ;;
    4) format="syslog_fortinet" ;;
    5) format="syslog_cisco_asa" ;;
    6) 
      read -r -p "Format personnalisé (ex: syslog_custom): " format
      ;;
    *) format="syslog_generic" ;;
  esac
  
  _sources_save_source "$name" "firewall" "$host" "$port" "$format" "true"
  _sources_configure_rsyslog "$name" "$port" "$format"
  
  success "Source firewall ajoutée : $name"
  info "Configuration rsyslog créée pour le port $port"
  echo
  info "📝 Sur votre firewall, configurez l'envoi syslog vers:"
  echo -e "   ${WHITE}IP: $(hostname -I | awk '{print $1}')${NC}"
  echo -e "   ${WHITE}Port: ${port}${NC}"
}

# Ajouter un serveur Linux
_sources_add_linux() {
  echo -e "${CYAN}${BOLD}═══ Configuration Serveur Linux ═══${NC}"
  echo
  
  read -r -p "Nom du serveur (ex: web-server-01): " name
  read -r -p "Adresse IP du serveur: " host
  read -r -p "Port rsyslog (défaut 514): " port
  port=${port:-514}
  
  _sources_save_source "$name" "linux_server" "$host" "$port" "syslog_rfc5424" "true"
  _sources_configure_rsyslog "$name" "$port" "syslog"
  
  success "Source Linux ajoutée : $name"
  echo
  info "📝 Sur le serveur distant, ajoutez dans /etc/rsyslog.conf:"
  echo -e "   ${WHITE}*.* @@$(hostname -I | awk '{print $1}'):${port}${NC}"
  echo -e "   ${DIM}Puis: sudo systemctl restart rsyslog${NC}"
}

# Ajouter une application (fichiers)
_sources_add_application() {
  echo -e "${CYAN}${BOLD}═══ Configuration Application ═══${NC}"
  echo
  
  read -r -p "Nom de l'application (ex: nginx-app): " name
  read -r -p "Chemin vers les logs (ex: /var/log/nginx/*.log): " log_path
  
  echo
  echo -e "${CYAN}Format des logs :${NC}"
  echo -e "  ${WHITE}1${NC} - JSON"
  echo -e "  ${WHITE}2${NC} - Nginx access/error"
  echo -e "  ${WHITE}3${NC} - Apache access"
  echo -e "  ${WHITE}4${NC} - Personnalisé (fichier)"
  echo
  read -r -p "Format [1-4]: " format_choice
  
  case "$format_choice" in
    1) format="json" ;;
    2) format="nginx" ;;
    3) format="apache" ;;
    4)
      read -r -p "Chemin du fichier de format (regex/pattern): " format_file
      if [[ -f "$format_file" ]]; then
        format=$(cat "$format_file")
      else
        warning "Fichier introuvable, utilisation format custom"
        format="custom"
      fi
      ;;
    *) format="plain" ;;
  esac
  
  _sources_save_source "$name" "application" "$log_path" "0" "$format" "true"
  _sources_configure_promtail_file "$name" "$log_path" "$format"
  
  success "Source application ajoutée : $name"
}

# Ajouter un conteneur Docker
_sources_add_docker() {
  echo -e "${CYAN}${BOLD}═══ Configuration Conteneur Docker ═══${NC}"
  echo
  
  read -r -p "Nom du conteneur (ou pattern, ex: nginx-*): " name
  read -r -p "Format des logs (json/plain): " format
  format=${format:-json}
  
  _sources_save_source "$name" "docker" "$name" "0" "$format" "true"
  _sources_configure_promtail_docker "$name" "$format"
  
  success "Source Docker ajoutée : $name"
}

# Ajouter une source personnalisée
_sources_add_custom() {
  echo -e "${CYAN}${BOLD}═══ Configuration Source Personnalisée ═══${NC}"
  echo
  
  read -r -p "Nom de la source: " name
  read -r -p "Type (syslog/file/tcp/udp): " type
  read -r -p "Host/Chemin: " host
  read -r -p "Port (si applicable, 0 sinon): " port
  port=${port:-0}
  
  echo
  echo -e "${YELLOW}Format personnalisé :${NC}"
  echo -e "  ${WHITE}1${NC} - Entrer le format directement"
  echo -e "  ${WHITE}2${NC} - Charger depuis un fichier"
  echo
  read -r -p "Choix [1-2]: " format_choice
  
  case "$format_choice" in
    1)
      read -r -p "Format (ex: syslog, json, regex): " format
      ;;
    2)
      read -r -p "Chemin du fichier de format: " format_file
      if [[ -f "$format_file" ]]; then
        format=$(cat "$format_file")
        success "Format chargé depuis $format_file"
      else
        error "Fichier introuvable"
        return 1
      fi
      ;;
    *)
      format="custom"
      ;;
  esac
  
  _sources_save_source "$name" "$type" "$host" "$port" "$format" "true"
  
  success "Source personnalisée ajoutée : $name"
}

# Sauvegarder une source dans le JSON
_sources_save_source() {
  local name="$1"
  local type="$2"
  local host="$3"
  local port="$4"
  local format="$5"
  local enabled="$6"
  
  local id=$(date +%s)
  
  local new_source=$(cat <<EOF
{
  "id": "$id",
  "name": "$name",
  "type": "$type",
  "host": "$host",
  "port": $port,
  "format": "$format",
  "enabled": $enabled,
  "created_at": "$(date -Iseconds)"
}
EOF
)
  
  if command -v jq >/dev/null 2>&1; then
    local tmp=$(mktemp)
    jq ".sources += [$new_source]" "$SOURCES_CONFIG" > "$tmp"
    mv "$tmp" "$SOURCES_CONFIG"
  else
    error "jq requis pour ajouter des sources"
    return 1
  fi
}

# Configurer rsyslog pour une source
_sources_configure_rsyslog() {
  local name="$1"
  local port="$2"
  local format="$3"
  
  local rsyslog_conf="/etc/rsyslog.d/20-hermes-${name}.conf"
  
  cat | sudo tee "$rsyslog_conf" > /dev/null <<EOF
# HERMES - Source: $name
# Format: $format

module(load="imudp")
input(type="imudp" port="$port" ruleset="hermes_${name}")

module(load="imtcp")
input(type="imtcp" port="$port" ruleset="hermes_${name}")

ruleset(name="hermes_${name}") {
    # Log vers fichier dédié
    action(type="omfile" file="/var/log/hermes/${name}.log")
    
    # Forward vers Promtail via syslog
    action(type="omfwd" Target="127.0.0.1" Port="1514" Protocol="tcp")
}
EOF
  
  # Créer le dossier de logs
  sudo mkdir -p /var/log/hermes
  sudo chown syslog:adm /var/log/hermes 2>/dev/null || true
  
  info "Configuration rsyslog créée : $rsyslog_conf"
}

# Configurer Promtail pour des fichiers
_sources_configure_promtail_file() {
  local name="$1"
  local log_path="$2"
  local format="$3"
  
  local promtail_config="${HERMES_BASE_DIR}/config/promtail/jobs/${name}.yaml"
  
  mkdir -p "${HERMES_BASE_DIR}/config/promtail/jobs"
  
  cat > "$promtail_config" <<EOF
# HERMES - Source: $name (application)
- job_name: ${name}
  static_configs:
    - targets:
        - localhost
      labels:
        job: ${name}
        source: application
        __path__: ${log_path}
  
  pipeline_stages:
EOF

  case "$format" in
    json)
      cat >> "$promtail_config" <<'EOF'
    - json:
        expressions:
          timestamp: time
          level: level
          message: message
    - labels:
        level:
EOF
      ;;
    nginx)
      cat >> "$promtail_config" <<'EOF'
    - regex:
        expression: '^(?P<remote_addr>[\w\.]+) - (?P<remote_user>[\w]+) \[(?P<time_local>.*)\] "(?P<method>\w+) (?P<request>.*) (?P<protocol>.*)" (?P<status>\d+) (?P<body_bytes_sent>\d+)'
    - labels:
        method:
        status:
EOF
      ;;
    apache)
      cat >> "$promtail_config" <<'EOF'
    - regex:
        expression: '^(?P<ip>[\w\.]+) - - \[(?P<time>.*)\] "(?P<method>\w+) (?P<uri>.*) (?P<protocol>.*)" (?P<status>\d+) (?P<size>\d+)'
    - labels:
        status:
EOF
      ;;
    *)
      cat >> "$promtail_config" <<'EOF'
    - match:
        selector: '{job="'${name}'"}'
        stages:
          - regex:
              expression: '.*'
EOF
      ;;
  esac
  
  info "Configuration Promtail créée : $promtail_config"
}

# Configurer Promtail pour Docker
_sources_configure_promtail_docker() {
  local name="$1"
  local format="$2"
  
  local promtail_config="${HERMES_BASE_DIR}/config/promtail/jobs/${name}-docker.yaml"
  
  mkdir -p "${HERMES_BASE_DIR}/config/promtail/jobs"
  
  cat > "$promtail_config" <<EOF
# HERMES - Source: $name (Docker)
- job_name: ${name}_docker
  docker_sd_configs:
    - host: unix:///var/run/docker.sock
      refresh_interval: 5s
      filters:
        - name: name
          values: ["${name}"]
  
  relabel_configs:
    - source_labels: ['__meta_docker_container_name']
      regex: '/(.*)'
      target_label: 'container'
    - source_labels: ['__meta_docker_container_log_stream']
      target_label: 'stream'
  
  pipeline_stages:
EOF

  if [[ "$format" == "json" ]]; then
    cat >> "$promtail_config" <<'EOF'
    - json:
        expressions:
          timestamp: time
          level: level
          message: msg
    - labels:
        level:
EOF
  else
    cat >> "$promtail_config" <<'EOF'
    - regex:
        expression: '^(?P<time>\S+) (?P<stream>\S+) (?P<log>.*)$'
    - timestamp:
        source: time
        format: RFC3339Nano
EOF
  fi
  
  info "Configuration Promtail Docker créée : $promtail_config"
}

# Supprimer une source
sources_remove() {
  section_title "Suppression d'une source"
  
  sources_list
  echo
  
  read -r -p "ID de la source à supprimer : " source_id
  
  if ! command -v jq >/dev/null 2>&1; then
    error "jq requis"
    return 1
  fi
  
  local name=$(jq -r ".sources[] | select(.id==\"$source_id\") | .name" "$SOURCES_CONFIG")
  
  if [[ -z "$name" ]]; then
    error "Source introuvable"
    return 1
  fi
  
  warning "Suppression de la source: $name"
  read -r -p "Confirmer ? (yes/no): " confirm
  
  if [[ "$confirm" != "yes" ]]; then
    warning "Annulé"
    return 0
  fi
  
  # Supprimer du JSON
  local tmp=$(mktemp)
  jq "del(.sources[] | select(.id==\"$source_id\"))" "$SOURCES_CONFIG" > "$tmp"
  mv "$tmp" "$SOURCES_CONFIG"
  
  # Supprimer les configs
  sudo rm -f "/etc/rsyslog.d/20-hermes-${name}.conf"
  rm -f "${HERMES_BASE_DIR}/config/promtail/jobs/${name}.yaml"
  rm -f "${HERMES_BASE_DIR}/config/promtail/jobs/${name}-docker.yaml"
  
  success "Source supprimée : $name"
  info "Relancez les services pour appliquer (option 5)"
}

# Appliquer les changements
sources_apply() {
  section_title "Application des changements"
  
  info "Rechargement de rsyslog..."
  sudo systemctl reload rsyslog 2>/dev/null || sudo systemctl restart rsyslog
  
  info "Redémarrage de Promtail..."
  sources_init_compose_cmd
  (cd "$HERMES_BASE_DIR" && sudo $COMPOSE_CMD restart promtail) || true
  
  success "Changements appliqués avec succès"
  info "Les nouvelles sources sont maintenant actives"
}

# Afficher l'aide pour configurer les sources distantes
sources_help() {
  section_title "Guide de configuration des sources"
  
  echo -e "${CYAN}${BOLD}📖 Configuration des équipements distants${NC}"
  echo
  
  echo -e "${BOLD}1. pfSense :${NC}"
  echo -e "   ${WHITE}Status > System Logs > Settings${NC}"
  echo -e "   ${DIM}• Enable Remote Logging${NC}"
  echo -e "   ${DIM}• Remote log servers: <IP_HERMES>:<PORT>${NC}"
  echo
  
  echo -e "${BOLD}2. Serveur Linux (rsyslog) :${NC}"
  echo -e "   ${WHITE}Ajoutez dans /etc/rsyslog.conf :${NC}"
  echo -e "   ${DIM}*.* @@<IP_HERMES>:514${NC}"
  echo -e "   ${DIM}Puis: sudo systemctl restart rsyslog${NC}"
  echo
  
  echo -e "${BOLD}3. Application :${NC}"
  echo -e "   ${DIM}Assurez-vous que HERMES peut lire les fichiers de logs${NC}"
  echo -e "   ${DIM}Permissions recommandées: chmod 644 /var/log/app/*.log${NC}"
  echo
  
  echo -e "${BOLD}4. Conteneur Docker :${NC}"
  echo -e "   ${DIM}Les conteneurs loggent automatiquement via le driver Docker${NC}"
  echo -e "   ${DIM}Utilisez: docker logs <container> pour vérifier${NC}"
  echo
}
