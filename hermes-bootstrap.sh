#!/bin/bash
# HERMES v3 - Bootstrap de réorganisation complète
# À lancer depuis le dossier HERMES existant

set -euo pipefail

# -----------------------------------------
# 1. Préparation & sauvegarde de l'existant
# -----------------------------------------

PROJECT_ROOT="$(pwd)"
TIMESTAMP="$(date +'%Y%m%d-%H%M%S')"
LEGACY_DIR="${PROJECT_ROOT}/_hermes_legacy_${TIMESTAMP}"

echo "🛡  HERMES v3 - Bootstrap"
echo "Répertoire courant : ${PROJECT_ROOT}"
echo "Un backup de l'existant sera créé dans : ${LEGACY_DIR}"
echo

read -p "➡️  Continuer et réorganiser complètement HERMES ? (yes/no) : " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "❌ Opération annulée."
  exit 1
fi

mkdir -p "$LEGACY_DIR"

# Fichiers/dossiers à sauvegarder s'ils existent
TO_BACKUP=(config dashboards scripts client docker-compose.yml docker-compose.yaml .env .env.example install.sh hermes.sh README.md)

for item in "${TO_BACKUP[@]}"; do
  if [[ -e "${PROJECT_ROOT}/${item}" ]]; then
    echo "➡️  Sauvegarde de ${item} -> ${LEGACY_DIR}/${item}"
    mv "${PROJECT_ROOT}/${item}" "${LEGACY_DIR}/" 2>/dev/null || mv "${PROJECT_ROOT}/${item}" "${LEGACY_DIR}/${item}" 2>/dev/null || true
  fi
done

echo
echo "✅ Sauvegarde terminée."
echo

# -----------------------------------------
# 2. Création de la nouvelle arborescence
# -----------------------------------------

echo "📁 Création de la nouvelle arborescence HERMES v3..."

mkdir -p \
  "${PROJECT_ROOT}/config" \
  "${PROJECT_ROOT}/dashboards/system" \
  "${PROJECT_ROOT}/dashboards/network" \
  "${PROJECT_ROOT}/dashboards/apps" \
  "${PROJECT_ROOT}/dashboards/templates" \
  "${PROJECT_ROOT}/dashboards/import" \
  "${PROJECT_ROOT}/modules" \
  "${PROJECT_ROOT}/scripts" \
  "${PROJECT_ROOT}/backups/db" \
  "${PROJECT_ROOT}/backups/volumes" \
  "${PROJECT_ROOT}/backups/reports" \
  "${PROJECT_ROOT}/logs"

echo "✅ Arborescence créée."
echo

# -----------------------------------------
# 3. Génération des fichiers de base
# -----------------------------------------

# 3.1 helpers.sh (couleurs, spinner, logs, détection)
cat > "${PROJECT_ROOT}/scripts/helpers.sh" << 'EOF'
#!/bin/bash
# Helpers communs HERMES v3

set -euo pipefail

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'

readonly BOLD='\033[1m'
readonly DIM='\033[2m'

readonly CHECKMARK="✓"
readonly CROSS="✗"
readonly ARROW="→"
readonly GEAR="⚙"
readonly ROCKET="🚀"
readonly SHIELD="🛡️"

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
LOG_DIR="${PROJECT_ROOT}/logs"
MAIN_LOG="${LOG_DIR}/hermes.log"

mkdir -p "$LOG_DIR"

log() {
  local level="$1"; shift
  local msg="$*"
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$MAIN_LOG"
}

info() {
  echo -e "${BLUE}[INFO]${NC} $*"
  log "INFO" "$*"
}

success() {
  echo -e "${GREEN}[${CHECKMARK}]${NC} ${GREEN}$*${NC}"
  log "SUCCESS" "$*"
}

warning() {
  echo -e "${YELLOW}[!]${NC} ${YELLOW}$*${NC}"
  log "WARNING" "$*"
}

error_msg() {
  echo -e "${RED}[${CROSS}]${NC} ${RED}$*${NC}" >&2
  log "ERROR" "$*"
}

section_title() {
  local title="$1"
  local width=55
  local title_len=${#title}
  local padding=$(( (width - title_len) / 2 ))
  local padding_right=$(( width - title_len - padding ))

  echo
  echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
  printf "${BOLD}${CYAN}║${NC}%*s${WHITE}${BOLD}%s${NC}%*s${BOLD}${CYAN}║${NC}\n" $padding "" "$title" $padding_right ""
  echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
  echo
}

spinner() {
  local pid="$1"
  local message="$2"
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0

  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) %10 ))
    printf "\r${CYAN}${spin:$i:1}${NC} %s" "$message"
    sleep 0.1
  done

  wait "$pid"
  local rc=$?

  if [ "$rc" -eq 0 ]; then
    printf "\r${GREEN}${CHECKMARK}${NC} %s\n" "$message"
    return 0
  else
    printf "\r${RED}${CROSS}${NC} %s (code=%s)\n" "$message" "$rc"
    return "$rc"
  fi
}

run_with_spinner() {
  local message="$1"; shift
  local log_file="${LOG_DIR}/cmd_$(date +'%Y%m%d-%H%M%S').log"

  ("$@" >"$log_file" 2>&1) &
  local pid=$!

  LAST_LOG="$log_file" spinner "$pid" "$message" || {
    echo
    warning "Dernières lignes du log :"
    tail -n 20 "$log_file" || true
    echo
    return 1
  }
  return 0
}

detect_distro() {
  if [[ ! -f /etc/os-release ]]; then
    echo "unknown"
    return 1
  fi
  . /etc/os-release
  echo "${ID:-unknown}"
}

detect_wsl() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "native"
  fi
}

detect_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
  elif docker-compose --version >/dev/null 2>&1; then
    echo "docker-compose"
  else
    echo ""
  fi
}

confirm() {
  local question="$1"
  echo
  read -r -p "$(echo -e ${YELLOW}${BOLD}$question" (yes/no): "${NC})" answer
  if [[ "$answer" != "yes" ]]; then
    warning "Opération annulée"
    return 1
  fi
  return 0
}
EOF
chmod +x "${PROJECT_ROOT}/scripts/helpers.sh"

# 3.2 core.sh (install, start/stop, status, health basique)
cat > "${PROJECT_ROOT}/modules/core.sh" << 'EOF'
#!/bin/bash
# Module core HERMES v3 : installation, démarrage, status

set -euo pipefail

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
COMPOSE_CMD="${COMPOSE_CMD:-}"

core_init_compose_cmd() {
  if [[ -n "$COMPOSE_CMD" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "Aucune commande docker-compose trouvée. Installez Docker Compose."
    exit 1
  fi
}

core_install_docker() {
  section_title "Installation de Docker"

  if command -v docker >/dev/null 2>&1; then
    success "Docker déjà installé: $(docker --version 2>/dev/null | head -n1)"
    return 0
  fi

  local distro
  distro="$(detect_distro)"
  info "Distribution détectée : ${distro}"

  case "$distro" in
    debian|ubuntu|kali|parrot)
      run_with_spinner "Installation Docker (Debian/Ubuntu)" bash -c '
        sudo apt-get update -qq
        sudo apt-get install -y ca-certificates curl gnupg lsb-release -qq
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(. /etc/os-release; echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -qq
      '
      ;;
    rhel|centos|rocky|almalinux|fedora)
      run_with_spinner "Installation Docker (RHEL-like)" bash -c '
        if command -v dnf >/dev/null 2>&1; then
          sudo dnf install -y dnf-plugins-core -q
          sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo -q
          sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin -q
        else
          sudo yum install -y yum-utils -q
          sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo -q
          sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin -q
        fi
      '
      ;;
    arch)
      run_with_spinner "Installation Docker (Arch)" bash -c '
        sudo pacman -Sy --noconfirm docker docker-compose
      '
      ;;
    *)
      warning "Distribution non reconnue (${distro}), tentative d'installation générique..."
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq && sudo apt-get install -y docker.io docker-compose -qq
      fi
      ;;
  esac

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl start docker 2>/dev/null || true
    sudo systemctl enable docker 2>/dev/null || true
  fi

  success "Docker installé."
}

core_install_dependencies() {
  section_title "Installation des dépendances HERMES"

  local distro
  distro="$(detect_distro)"

  case "$distro" in
    debian|ubuntu|kali|parrot)
      run_with_spinner "Installation des dépendances système" bash -c '
        sudo apt-get update -qq
        sudo apt-get install -y jq curl wget rsyslog git whiptail ca-certificates gnupg lsb-release -qq
      '
      ;;
    rhel|centos|rocky|almalinux|fedora)
      run_with_spinner "Installation des dépendances système" bash -c '
        sudo dnf install -y jq curl wget rsyslog git newt ca-certificates -q
      '
      ;;
    arch)
      run_with_spinner "Installation des dépendances système" bash -c '
        sudo pacman -Sy --noconfirm jq curl wget rsyslog git
      '
      ;;
    *)
      warning "Dépendances : installation générique"
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq && sudo apt-get install -y jq curl wget rsyslog git -qq
      fi
      ;;
  esac

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl start rsyslog 2>/dev/null || true
    sudo systemctl enable rsyslog 2>/dev/null || true
  fi

  success "Dépendances système installées."
}

core_setup_env() {
  section_title "Configuration de l'environnement (.env)"

  local env_path="${HERMES_BASE_DIR}/.env"
  local example_path="${HERMES_BASE_DIR}/.env.example"

  if [[ -f "$env_path" ]]; then
    info ".env existant détecté, non modifié."
    return 0
  fi

  if [[ -f "$example_path" ]]; then
    cp "$example_path" "$env_path"
    info "Fichier .env créé à partir de .env.example"
  else
    info "Création d'un .env minimal..."
    cat > "$env_path" <<EOF2
BASE_DIR=${HERMES_BASE_DIR}
ARCHIVES_DIR=${HERMES_BASE_DIR}/backups
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin
INFLUXDB_INIT_ADMIN_TOKEN=$(openssl rand -hex 32)
TZ=Europe/Paris
EOF2
    info "Fichier .env minimal généré."
  fi

  success ".env prêt. Pensez à ajuster les mots de passe."
}

core_check_ports() {
  section_title "Vérification des ports"

  local ports=("3000" "9090" "3100" "8086")
  local conflict=0

  for p in "${ports[@]}"; do
    if ss -lnt 2>/dev/null | grep -q ":$p "; then
      warning "Port ${p} déjà utilisé (ss)."
      conflict=1
    elif lsof -iTCP:"$p" -sTCP:LISTEN &>/dev/null; then
      warning "Port ${p} déjà utilisé (lsof)."
      conflict=1
    else
      success "Port ${p} disponible."
    fi
  done

  if [[ "$conflict" -eq 1 ]]; then
    warning "Certains ports sont occupés. Adaptez votre docker-compose.yml si nécessaire."
  fi
}

core_start_stack() {
  section_title "Démarrage de la stack HERMES"
  core_init_compose_cmd

  if [[ ! -f "${HERMES_BASE_DIR}/docker-compose.yml" ]]; then
    error_msg "docker-compose.yml introuvable dans ${HERMES_BASE_DIR}."
    exit 1
  fi

  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD up -d) &
  spinner $! "Lancement des conteneurs Docker"
  success "Stack démarrée."
}

core_stop_stack() {
  section_title "Arrêt de la stack HERMES"
  core_init_compose_cmd

  if [[ ! -f "${HERMES_BASE_DIR}/docker-compose.yml" ]]; then
    warning "Aucun docker-compose.yml trouvé, rien à arrêter."
    return 0
  fi

  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD down) &
  spinner $! "Arrêt des conteneurs Docker"
  success "Stack arrêtée."
}

core_restart_stack() {
  core_stop_stack
  core_start_stack
}

core_status() {
  section_title "État des services Docker"
  core_init_compose_cmd

  if [[ ! -f "${HERMES_BASE_DIR}/docker-compose.yml" ]]; then
    warning "docker-compose.yml introuvable."
    return 0
  fi

  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD ps)
}

core_full_install() {
  section_title "Installation complète HERMES"
  core_install_docker
  core_install_dependencies
  core_setup_env
  core_check_ports
  core_start_stack
}
EOF
chmod +x "${PROJECT_ROOT}/modules/core.sh"

# 3.3 dashboards.sh (gestion Grafana : list / import / export / reload)
cat > "${PROJECT_ROOT}/modules/dashboards.sh" << 'EOF'
#!/bin/bash
# Module dashboards Grafana pour HERMES v3

set -euo pipefail

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
COMPOSE_CMD="${COMPOSE_CMD:-}"

dash_init_env() {
  if [[ -f "${HERMES_BASE_DIR}/.env" ]]; then
    # shellcheck disable=SC2046
    export $(grep -E '^(GRAFANA_ADMIN_USER|GRAFANA_ADMIN_PASSWORD|BASE_DIR|TZ)=' "${HERMES_BASE_DIR}/.env" | xargs -d '\n' -I {} echo {})
  fi
  GRAFANA_ADMIN_USER="${GRAFANA_ADMIN_USER:-admin}"
  GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin}"
  GRAFANA_URL="${GRAFANA_URL:-http://127.0.0.1:3000}"
}

dash_init_compose_cmd() {
  if [[ -n "${COMPOSE_CMD:-}" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "docker-compose introuvable."
    exit 1
  fi
}

dash_check_grafana_up() {
  dash_init_env
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" "${GRAFANA_URL}/api/health" || echo "000")
  if [[ "$code" != "200" ]]; then
    error_msg "Grafana ne répond pas (${code}). Assurez-vous que la stack est démarrée."
    return 1
  fi
  success "Grafana est joignable (${GRAFANA_URL})."
}

dash_reload_grafana() {
  section_title "Redémarrage de Grafana"
  dash_init_compose_cmd
  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD restart grafana) &
  spinner $! "Redémarrage Grafana"
  success "Grafana redémarré."
}

dash_list_dashboards() {
  section_title "Liste des dashboards Grafana"
  dash_check_grafana_up || return 1
  if command -v jq >/dev/null 2>&1; then
    curl -s -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" \
      "${GRAFANA_URL}/api/search?query=" \
      | jq -r '.[] | "\(.id)\t\(.uid)\t\(.title)"' \
      || error_msg "Impossible de lister les dashboards."
  else
    curl -s -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" \
      "${GRAFANA_URL}/api/search?query=" \
      || error_msg "Impossible de lister les dashboards (jq indisponible)."
  fi
}

dash_import_from_file() {
  local file_path="$1"

  section_title "Import d'un dashboard Grafana"

  if [[ ! -f "$file_path" ]]; then
    error_msg "Fichier introuvable : $file_path"
    return 1
  fi

  dash_check_grafana_up || return 1

  local json
  json="$(cat "$file_path")"

  if ! grep -q '"dashboard"' <<< "$json"; then
    warning "Le JSON ne semble pas être un export complet Grafana."
    warning "On va l'envelopper dans {'dashboard': ..., 'overwrite': true}"
    json="{\"dashboard\": ${json}, \"overwrite\": true}"
  fi

  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" \
    -H "Content-Type: application/json" \
    -X POST "${GRAFANA_URL}/api/dashboards/db" \
    --data-binary @"<(printf '%s' "$json")" || echo "000")

  if [[ "$code" == "200" || "$code" == "202" ]]; then
    success "Dashboard importé avec succès (${file_path})."
  else
    error_msg "Échec de l'import (HTTP ${code})."
    return 1
  fi
}

dash_interactive_import() {
  section_title "Ajout d'un dashboard Grafana"
  read -r -p "Chemin du fichier JSON à importer : " file_path
  dash_import_from_file "$file_path"
  dash_reload_grafana || true
}

dash_export_dashboard() {
  section_title "Export d'un dashboard Grafana"

  dash_check_grafana_up || return 1
  read -r -p "UID du dashboard à exporter : " uid
  read -r -p "Chemin de sortie (ex: dashboards/export_mon_dash.json) : " out

  mkdir -p "$(dirname "$out")"

  local code
  code=$(curl -s -o "$out" -w "%{http_code}" \
    -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" \
    "${GRAFANA_URL}/api/dashboards/uid/${uid}" || echo "000")

  if [[ "$code" == "200" ]]; then
    success "Dashboard exporté vers ${out}."
  else
    rm -f "$out"
    error_msg "Échec de l'export (HTTP ${code})."
    return 1
  fi
}

dash_install_template() {
  section_title "Installation d'un dashboard depuis templates/"

  local tpl_dir="${HERMES_BASE_DIR}/dashboards/templates"

  if [[ ! -d "$tpl_dir" ]]; then
    error_msg "Répertoire templates introuvable : $tpl_dir"
    return 1
  fi

  echo "Templates disponibles :"
  ls -1 "$tpl_dir"/*.json 2>/dev/null || {
    warning "Aucun template JSON trouvé dans ${tpl_dir}."
    return 0
  }
  echo
  read -r -p "Nom du fichier template (sans le chemin) : " tpl_name

  local file="${tpl_dir}/${tpl_name}"
  if [[ ! -f "$file" ]]; then
    error_msg "Template introuvable : $file"
    return 1
  fi

  dash_import_from_file "$file"
  dash_reload_grafana || true
}
EOF
chmod +x "${PROJECT_ROOT}/modules/dashboards.sh"

# 3.4 health.sh (healthchecks)
cat > "${PROJECT_ROOT}/modules/health.sh" << 'EOF'
#!/bin/bash
# Module health HERMES v3

set -euo pipefail

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
COMPOSE_CMD="${COMPOSE_CMD:-}"

health_init_compose_cmd() {
  if [[ -n "${COMPOSE_CMD:-}" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "docker-compose introuvable."
    exit 1
  fi
}

health_check_services() {
  section_title "Healthcheck des services HERMES"
  health_init_compose_cmd

  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD ps --format 'table {{.Name}}\t{{.State}}\t{{.Status}}') || {
    error_msg "Impossible de récupérer l'état des services."
    return 1
  }

  echo
  info "Détail des healthchecks (si définis) :"
  echo

  local containers
  containers=$(cd "$HERMES_BASE_DIR" && $COMPOSE_CMD ps -q || true)

  for cid in $containers; do
    local name
    name=$(docker inspect -f '{{.Name}}' "$cid" | sed 's/^\/\(.*\)/\1/')
    local health
    health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' "$cid" 2>/dev/null || echo "n/a")
    if [[ "$health" == "healthy" ]]; then
      echo -e "${GREEN}[OK]${NC} ${WHITE}${name}${NC} - health=${GREEN}${health}${NC}"
    elif [[ "$health" == "n/a" ]]; then
      echo -e "${YELLOW}[~]${NC} ${WHITE}${name}${NC} - aucun healthcheck défini"
    else
      echo -e "${RED}[KO]${NC} ${WHITE}${name}${NC} - health=${RED}${health}${NC}"
    fi
  done
}

health_ports() {
  section_title "Vérification des ports critiques"

  local ports=("3000:Grafana" "9090:Prometheus" "3100:Loki" "8086:InfluxDB")
  for entry in "${ports[@]}"; do
    local p="${entry%%:*}"
    local label="${entry##*:}"
    if ss -lnt 2>/dev/null | grep -q ":$p "; then
      success "Port ${p} (${label}) écoute."
    else
      warning "Port ${p} (${label}) ne semble pas écouter."
    fi
  done
}
EOF
chmod +x "${PROJECT_ROOT}/modules/health.sh"

# 3.5 backup.sh (backup simple config + volumes)
cat > "${PROJECT_ROOT}/modules/backup.sh" << 'EOF'
#!/bin/bash
# Module backup HERMES v3

set -euo pipefail

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
BACKUP_DIR="${HERMES_BASE_DIR}/backups"
COMPOSE_CMD="${COMPOSE_CMD:-}"

backup_init_compose_cmd() {
  if [[ -n "${COMPOSE_CMD:-}" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "docker-compose introuvable."
    exit 1
  fi
}

backup_config() {
  section_title "Sauvegarde de la configuration HERMES"

  mkdir -p "${BACKUP_DIR}/db" "${BACKUP_DIR}/volumes" "${BACKUP_DIR}/reports"
  local ts
  ts="$(date +'%Y%m%d-%H%M%S')"
  local out="${BACKUP_DIR}/hermes_config_${ts}.tar.gz"

  tar -czf "$out" \
    -C "$HERMES_BASE_DIR" \
    docker-compose.yml .env config dashboards 2>/dev/null || true

  success "Config sauvegardée dans ${out}"
}

backup_volumes() {
  section_title "Sauvegarde des volumes Docker HERMES"

  mkdir -p "${BACKUP_DIR}/volumes"
  local ts
  ts="$(date +'%Y%m%d-%H%M%S')"

  local vols=("hermes-grafana-storage" "hermes-loki-storage" "hermes-loki-wal" "hermes-prometheus-storage" "hermes-influxdb-storage")

  for v in "${vols[@]}"; do
    if docker volume inspect "$v" >/dev/null 2>&1; then
      local out="${BACKUP_DIR}/vol_${v}_${ts}.tar.gz"
      info "Sauvegarde volume ${v} -> ${out}"
      docker run --rm -v "${v}:/data" -v "${BACKUP_DIR}/volumes:/backup" alpine \
        sh -c "cd /data && tar -czf /backup/$(basename "$out") ." || warning "Échec sauvegarde volume ${v}"
    else
      warning "Volume inexistant : ${v}"
    fi
  done
  success "Sauvegarde volumes terminée (voir ${BACKUP_DIR}/volumes)."
}

backup_all() {
  backup_config
  backup_volumes
}
EOF
chmod +x "${PROJECT_ROOT}/modules/backup.sh"

# 3.6 logs.sh (logs & debug)
cat > "${PROJECT_ROOT}/modules/logs.sh" << 'EOF'
#!/bin/bash
# Module logs / debug HERMES v3

set -euo pipefail

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
COMPOSE_CMD="${COMPOSE_CMD:-}"

logs_init_compose_cmd() {
  if [[ -n "${COMPOSE_CMD:-}" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "docker-compose introuvable."
    exit 1
  fi
}

logs_tail_service() {
  logs_init_compose_cmd
  section_title "Logs d'un service Docker"

  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD ps --services) || {
    error_msg "Impossible de lister les services."
    return 1
  }
  echo
  read -r -p "Nom du service à suivre (exact) : " svc
  echo
  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD logs -f "$svc")
}

logs_export_all() {
  logs_init_compose_cmd
  section_title "Export global des logs Docker"

  local out_dir="${HERMES_BASE_DIR}/backups/reports"
  mkdir -p "$out_dir"
  local ts
  ts="$(date +'%Y%m%d-%H%M%S')"
  local out="${out_dir}/hermes_logs_${ts}.txt"

  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD logs) >"$out" 2>&1 || true
  success "Logs exportés dans ${out}"
}
EOF
chmod +x "${PROJECT_ROOT}/modules/logs.sh"

# 3.7 Script principal hermes.sh (menu)
cat > "${PROJECT_ROOT}/hermes.sh" << 'EOF'
#!/bin/bash
# HERMES v3 - Script principal de gestion

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT
export HERMES_BASE_DIR="$PROJECT_ROOT"

source "${PROJECT_ROOT}/scripts/helpers.sh"
source "${PROJECT_ROOT}/modules/core.sh"
source "${PROJECT_ROOT}/modules/dashboards.sh"
source "${PROJECT_ROOT}/modules/health.sh"
source "${PROJECT_ROOT}/modules/backup.sh"
source "${PROJECT_ROOT}/modules/logs.sh"

handle_error() {
  local code="$1"
  local line="$2"
  echo
  echo -e "${RED}${BOLD}╔═══════════════════════════════════════════════╗${NC}"
  echo -e "${RED}${BOLD}║${NC}    ${WHITE}❌ Une erreur est survenue${NC}               ${RED}${BOLD}║${NC}"
  echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}Code d'erreur:${NC} ${code}"
  echo -e "${YELLOW}Ligne:${NC} ${line}"
  echo
  if [[ -n "${LAST_LOG:-}" && -f "${LAST_LOG:-}" ]]; then
    echo -e "${YELLOW}${BOLD}Dernières lignes du log :${NC}"
    tail -n 20 "${LAST_LOG}" || true
    echo
  fi
  echo -e "${DIM}Log principal : ${MAIN_LOG}${NC}"
  exit "$code"
}

trap 'handle_error $? $LINENO' ERR

show_banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  cat << "EOF2"
    ╔════════════════════════════════════════════════════════════════╗
    ║                                                                ║
    ║      ██╗  ██╗███████╗██████╗ ███╗   ███╗███████╗███████╗       ║
    ║      ██║  ██║██╔════╝██╔══██╗████╗ ████║██╔════╝██╔════╝       ║
    ║      ███████║█████╗  ██████╔╝██╔████╔██║█████╗  ███████╗       ║
    ║      ██╔══██║██╔══╝  ██╔══██╗██║╚██╔╝██║██╔══╝  ╚════██║       ║
    ║      ██║  ██║███████╗██║  ██║██║ ╚═╝ ██║███████╗███████║       ║
    ║      ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝       ║
    ║                                                                ║
    ║  Highly Efficient Real-time Monitoring and Event System        ║
    ║                                                                ║
    ╚════════════════════════════════════════════════════════════════╝
EOF2
  echo -e "${NC}"
  echo -e "${CYAN}${BOLD}   Plateforme de monitoring centralisé • Logs • Métriques${NC}"
  echo
}

show_menu() {
  show_banner
  echo -e "${MAGENTA}${BOLD}──── INSTALLATION & CONFIGURATION ─────────────────────────────${NC}"
  echo -e "  ${WHITE}1${NC}  Installation complète (Docker + dépendances + stack)"
  echo -e "  ${WHITE}2${NC}  Démarrer la stack HERMES"
  echo -e "  ${WHITE}3${NC}  Arrêter la stack HERMES"
  echo -e "  ${WHITE}4${NC}  Redémarrer la stack"
  echo -e "  ${WHITE}5${NC}  Afficher l'état des services"
  echo
  echo -e "${MAGENTA}${BOLD}──── DASHBOARDS GRAFANA ──────────────────────────────────────${NC}"
  echo -e "  ${WHITE}6${NC}  Lister les dashboards"
  echo -e "  ${WHITE}7${NC}  Importer un dashboard (fichier JSON)"
  echo -e "  ${WHITE}8${NC}  Installer un dashboard depuis templates/"
  echo -e "  ${WHITE}9${NC}  Exporter un dashboard existant"
  echo -e "  ${WHITE}10${NC} Recharger Grafana"
  echo
  echo -e "${MAGENTA}${BOLD}──── BACKUPS & LOGS ──────────────────────────────────────────${NC}"
  echo -e "  ${WHITE}11${NC} Sauvegarde complète (config + volumes)"
  echo -e "  ${WHITE}12${NC} Suivre les logs d'un service"
  echo -e "  ${WHITE}13${NC} Exporter tous les logs Docker"
  echo
  echo -e "${MAGENTA}${BOLD}──── HEALTHCHECK & DIAGNOSTIC ───────────────────────────────${NC}"
  echo -e "  ${WHITE}14${NC} Vérifier la santé des services"
  echo -e "  ${WHITE}15${NC} Vérifier les ports critiques"
  echo
  echo -e "${MAGENTA}${BOLD}──── AUTRES ─────────────────────────────────────────────────${NC}"
  echo -e "  ${WHITE}0${NC}  Quitter"
  echo
  read -r -p "$(echo -e ${MAGENTA}${BOLD}👉 Votre choix [0-15]: ${NC})" choice
  echo
  case "$choice" in
    1) core_full_install ;;
    2) core_start_stack ;;
    3) core_stop_stack ;;
    4) core_restart_stack ;;
    5) core_status ;;
    6) dash_list_dashboards ;;
    7) dash_interactive_import ;;
    8) dash_install_template ;;
    9) dash_export_dashboard ;;
    10) dash_reload_grafana ;;
    11) backup_all ;;
    12) logs_tail_service ;;
    13) logs_export_all ;;
    14) health_check_services ;;
    15) health_ports ;;
    0) echo "Au revoir."; exit 0 ;;
    *) echo -e "${RED}Choix invalide.${NC}"; sleep 1 ;;
  esac

  echo
  read -r -p "Appuyez sur Entrée pour revenir au menu..." _
}

while true; do
  show_menu
done
EOF
chmod +x "${PROJECT_ROOT}/hermes.sh"

echo
echo "✅ Bootstrap HERMES v3 terminé."
echo "Ancien contenu sauvegardé dans : ${LEGACY_DIR}"
echo
echo "Utilisation :"
echo "  cd \"${PROJECT_ROOT}\""
echo "  ./hermes.sh"
echo
echo "Commence par l'option 1 pour une installation complète."
