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
