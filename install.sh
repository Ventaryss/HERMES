#!/bin/bash

# ════════════════════════════════════════════════════════════════════════
# HERMES - Highly Efficient Real-time Monitoring and Event System
# Script d'installation interactif
# ════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Trap pour gérer les erreurs
trap 'handle_error $? $LINENO' ERR INT TERM

# ══════════════════════════════════
# COULEURS ET STYLES
# ══════════════════════════════════

# Couleurs ANSI
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Styles
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly UNDERLINE='\033[4m'
readonly BLINK='\033[5m'

# Emojis/Symboles
readonly CHECKMARK="✓"
readonly CROSS="✗"
readonly ARROW="→"
readonly STAR="★"
readonly GEAR="⚙"
readonly ROCKET="🚀"
readonly SHIELD="🛡️"

# ════════════════════════════════════
# GESTION DES ERREURS
# ════════════════════════════════════

handle_error() {
    local exit_code=$1
    local line_number=$2
    
    echo
    echo -e "${RED}${BOLD}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${RED}${BOLD}║${NC}    ${WHITE}❌ Une erreur est survenue${NC}               ${RED}${BOLD}║${NC}"
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Code d'erreur:${NC} $exit_code"
    echo -e "${YELLOW}Ligne:${NC} $line_number"
    echo
    
    # Afficher le log si disponible
    if [ -n "${LAST_LOG:-}" ] && [ -f "$LAST_LOG" ]; then
        echo -e "${YELLOW}${BOLD}═══ Dernières lignes du log ═══${NC}"
        tail -n 30 "$LAST_LOG" 2>/dev/null || true
        echo -e "${YELLOW}${BOLD}═══════════════════════════════${NC}"
        echo
        echo -e "${DIM}Log complet disponible: $LAST_LOG${NC}"
    fi
    
    echo -e "${CYAN}Pour plus d'aide, consultez le README ou les logs${NC}"
    echo
    
    exit $exit_code
}

# ═══════════════════════════════
# VARIABLES GLOBALES
# ═══════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${HOME}/HERMES"
LOG_FILE="${BASE_DIR}/installation.log"
INSTALL_START_TIME=$(date +%s)

# ════════════════════════════════════
# FONCTIONS D'AFFICHAGE
# ════════════════════════════════════

# Bannière principale
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║      ██╗  ██╗███████╗██████╗ ███╗   ███╗███████╗███████╗      ║
    ║      ██║  ██║██╔════╝██╔══██╗████╗ ████║██╔════╝██╔════╝      ║
    ║      ███████║█████╗  ██████╔╝██╔████╔██║█████╗  ███████╗      ║
    ║      ██╔══██║██╔══╝  ██╔══██╗██║╚██╔╝██║██╔══╝  ╚════██║      ║
    ║      ██║  ██║███████╗██║  ██║██║ ╚═╝ ██║███████╗███████║      ║
    ║      ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝      ║
    ║                                                               ║
    ║            Highly Efficient Real-time Monitoring              ║
    ║                   and Event System                            ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Barre de séparation
separator() {
    echo -e "${DIM}${1:-─────────────────────────────────────────────────────────────}${NC}"
}

# Titre de section
section_title() {
    local title="$1"
    local width=47
    local title_len=${#title}
    local padding=$(( (width - title_len) / 2 ))
    local padding_right=$(( width - title_len - padding ))
    
    echo
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    printf "${BOLD}${CYAN}║${NC}%*s${BOLD}${WHITE}%s${NC}%*s${BOLD}${CYAN}║${NC}\n" $padding "" "$title" $padding_right ""
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo
}

# Messages colorés
info() {
    echo -e "${BLUE}[INFO]${NC} ${1}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE" 2>/dev/null || true
}

success() {
    echo -e "${GREEN}[${CHECKMARK}]${NC} ${GREEN}${1}${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_FILE" 2>/dev/null || true
}

warning() {
    echo -e "${YELLOW}[!]${NC} ${YELLOW}${1}${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING] $1" >> "$LOG_FILE" 2>/dev/null || true
}

error() {
    echo -e "${RED}[${CROSS}]${NC} ${RED}${1}${NC}" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE" 2>/dev/null || true
}

# Barre de progression
progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    # Effacer la ligne
    printf "\r\033[K"
    
    # Construire la barre
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    
    printf "${CYAN}[${bar}]${NC} ${WHITE}%3d%%${NC}" "$percentage"
}

# Spinner d'attente avec gestion d'erreur
spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${CYAN}${spin:$i:1}${NC} ${message}"
        sleep 0.1
    done
    
    # Vérifier le code de retour
    wait $pid
    local rc=$?
    
    if [ $rc -eq 0 ]; then
        printf "\r${GREEN}${CHECKMARK}${NC} ${message}\n"
        return 0
    else
        printf "\r${RED}✗${NC} ${message}\n"
        error "La commande a échoué avec le code: $rc"
        
        # Si un fichier de log existe, afficher les dernières lignes
        if [ -n "${LAST_LOG:-}" ] && [ -f "$LAST_LOG" ]; then
            echo
            echo -e "${YELLOW}${BOLD}═══ Dernières lignes du log ═══${NC}"
            tail -n 30 "$LAST_LOG" 2>/dev/null || true
            echo -e "${YELLOW}${BOLD}═══════════════════════════════${NC}"
            echo
        fi
        return $rc
    fi
}

# Pause avec compte à rebours
pause_with_countdown() {
    local seconds=${1:-3}
    local message=${2:-"Continuation dans"}
    
    for ((i=seconds; i>0; i--)); do
        echo -ne "\r${CYAN}${message} ${WHITE}${i}${NC} secondes...  "
        sleep 1
    done
    echo -e "\r${GREEN}${CHECKMARK}${NC} C'est parti !                    "
}

# ════════════════════════════════════════
# FONCTIONS DE VÉRIFICATION
# ════════════════════════════════════════

# Vérifier si whiptail est disponible
check_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        info "Installation de whiptail pour l'interface graphique..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y whiptail -qq
        elif command -v yum &> /dev/null; then
            sudo yum install -y newt -q
        fi
    fi
}

# ══════════════════════════════════════
# DÉTECTION SYSTÈME AVANCÉE
# ══════════════════════════════════════

# Variables globales pour la distribution
DISTRO_BASE=""
DISTRO_VERSION=""
DISTRO_CODENAME=""
DISTRO_FAMILY=""

# Détecter et normaliser la distribution
detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        error "Impossible de détecter la distribution"
        return 1
    fi
    
    . /etc/os-release
    
    DISTRO_BASE="$ID"
    DISTRO_VERSION="${VERSION_ID:-unknown}"
    DISTRO_CODENAME="${VERSION_CODENAME:-unknown}"
    
    # Normaliser les distributions basées sur d'autres
    case "$DISTRO_BASE" in
        kali|parrot)
            DISTRO_BASE="debian"
            DISTRO_VERSION="12"  # Basé sur Bookworm
            DISTRO_CODENAME="bookworm"
            ;;
        linuxmint|pop)
            DISTRO_BASE="ubuntu"
            ;;
        rocky|alma|almalinux)
            DISTRO_BASE="rhel"
            ;;
        centos)
            if [[ "$VERSION_ID" == "8" ]] || [[ "$VERSION_ID" == "9" ]]; then
                DISTRO_BASE="rhel"
            fi
            ;;
    esac
    
    # Déterminer la famille
    case "$DISTRO_BASE" in
        debian|ubuntu)
            DISTRO_FAMILY="debian"
            ;;
        rhel|centos|fedora|rocky|alma)
            DISTRO_FAMILY="rhel"
            ;;
        arch|manjaro)
            DISTRO_FAMILY="arch"
            ;;
        opensuse*|sles)
            DISTRO_FAMILY="suse"
            ;;
        *)
            DISTRO_FAMILY="unknown"
            ;;
    esac
    
    # Cas spécial Debian 13 (Trixie) - utiliser Bookworm pour PHP
    if [[ "$DISTRO_BASE" == "debian" ]] && [[ "$DISTRO_VERSION" == "13" || "$DISTRO_CODENAME" == "trixie" ]]; then
        warning "Debian 13 (Trixie) détecté - utilisation des repos Bookworm pour compatibilité"
        DISTRO_CODENAME="bookworm"
        DISTRO_VERSION="12"
    fi
    
    echo "$DISTRO_BASE"
}

# Afficher les informations système
show_system_info() {
    info "Distribution: ${BOLD}${DISTRO_BASE} ${DISTRO_VERSION}${NC}"
    info "Famille: ${BOLD}${DISTRO_FAMILY}${NC}"
    if [[ "$DISTRO_CODENAME" != "unknown" ]]; then
        info "Codename: ${BOLD}${DISTRO_CODENAME}${NC}"
    fi
}

# Vérifier les permissions sudo
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        warning "Certaines opérations nécessitent sudo"
        sudo -v || { error "Permissions sudo requises"; exit 1; }
    fi
}

# ════════════════════════════════════════════
# INSTALLATION DES DÉPENDANCES
# ════════════════════════════════════════════

install_docker() {
    section_title "Installation de Docker"
    
    if command -v docker &> /dev/null; then
        success "Docker déjà installé: $(docker --version | cut -d' ' -f3)"
        return 0
    fi
    
    info "Installation de Docker pour ${BOLD}${DISTRO_BASE} ${DISTRO_VERSION}${NC}..."
    
    case "$DISTRO_FAMILY" in
        debian)
            LAST_LOG=$(mktemp /tmp/hermes_docker_XXXX.log)
            {
                sudo apt-get update -qq
                sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common -qq
                
                # Créer le répertoire pour les clés
                sudo mkdir -p /etc/apt/keyrings
                
                # Ajouter la clé GPG Docker
                if [[ "$DISTRO_BASE" == "debian" ]]; then
                    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${DISTRO_CODENAME} stable" | \
                        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                else
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
                        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                fi
                
                sudo apt-get update -qq
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -qq
            } > "$LAST_LOG" 2>&1 &
            spinner $! "Installation de Docker (Debian/Ubuntu)" || return 1
            rm -f "$LAST_LOG"
            unset LAST_LOG
            ;;
            
        rhel)
            LAST_LOG=$(mktemp /tmp/hermes_docker_XXXX.log)
            {
                # Installer les dépendances
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y dnf-plugins-core -q
                    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo -q
                    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -q
                else
                    sudo yum install -y yum-utils -q
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo -q
                    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -q
                fi
            } > "$LAST_LOG" 2>&1 &
            spinner $! "Installation de Docker (RHEL/CentOS)" || return 1
            rm -f "$LAST_LOG"
            unset LAST_LOG
            ;;
            
        arch)
            LAST_LOG=$(mktemp /tmp/hermes_docker_XXXX.log)
            {
                sudo pacman -Sy --noconfirm docker docker-compose
            } > "$LAST_LOG" 2>&1 &
            spinner $! "Installation de Docker (Arch)" || return 1
            rm -f "$LAST_LOG"
            unset LAST_LOG
            ;;
            
        suse)
            LAST_LOG=$(mktemp /tmp/hermes_docker_XXXX.log)
            {
                sudo zypper install -y docker docker-compose
            } > "$LAST_LOG" 2>&1 &
            spinner $! "Installation de Docker (SUSE)" || return 1
            rm -f "$LAST_LOG"
            unset LAST_LOG
            ;;
            
        *)
            error "Famille de distribution non supportée: $DISTRO_FAMILY"
            warning "Distributions supportées: Debian, Ubuntu, CentOS, RHEL, Fedora, Rocky, AlmaLinux, Kali, Arch, SUSE"
            return 1
            ;;
    esac
    
    # Démarrer et activer Docker
    sudo systemctl start docker 2>/dev/null || sudo systemctl start docker.service 2>/dev/null
    sudo systemctl enable docker 2>/dev/null || sudo systemctl enable docker.service 2>/dev/null
    
    # Ajouter l'utilisateur au groupe docker
    sudo usermod -aG docker "$USER" 2>/dev/null || true
    
    success "Docker installé avec succès"
    warning "Vous devrez peut-être vous reconnecter pour utiliser Docker sans sudo"
}

install_dependencies() {
    section_title "Installation des dépendances"
    
    info "Installation des outils système..."
    
    case "$DISTRO_FAMILY" in
        debian)
            LAST_LOG=$(mktemp /tmp/hermes_deps_XXXX.log)
            {
                sudo apt-get update -qq
                sudo apt-get install -y dos2unix jq curl wget rsyslog whiptail git ca-certificates gnupg lsb-release -qq
            } > "$LAST_LOG" 2>&1 &
            spinner $! "Installation des dépendances (Debian/Ubuntu)" || return 1
            rm -f "$LAST_LOG"
            unset LAST_LOG
            ;;
            
        rhel)
            LAST_LOG=$(mktemp /tmp/hermes_deps_XXXX.log)
            {
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y dos2unix jq curl wget rsyslog newt git ca-certificates -q
                else
                    sudo yum install -y dos2unix jq curl wget rsyslog newt git ca-certificates -q
                fi
            } > "$LAST_LOG" 2>&1 &
            spinner $! "Installation des dépendances (RHEL/CentOS)" || return 1
            rm -f "$LAST_LOG"
            unset LAST_LOG
            ;;
            
        arch)
            LAST_LOG=$(mktemp /tmp/hermes_deps_XXXX.log)
            {
                sudo pacman -Sy --noconfirm dos2unix jq curl wget rsyslog git ca-certificates
            } > "$LAST_LOG" 2>&1 &
            spinner $! "Installation des dépendances (Arch)" || return 1
            rm -f "$LAST_LOG"
            unset LAST_LOG
            ;;
            
        suse)
            LAST_LOG=$(mktemp /tmp/hermes_deps_XXXX.log)
            {
                sudo zypper install -y dos2unix jq curl wget rsyslog git ca-certificates
            } > "$LAST_LOG" 2>&1 &
            spinner $! "Installation des dépendances (SUSE)" || return 1
            rm -f "$LAST_LOG"
            unset LAST_LOG
            ;;
            
        *)
            warning "Famille non reconnue, tentative d'installation basique..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update -qq && sudo apt-get install -y dos2unix jq curl wget rsyslog git -qq
            elif command -v yum &> /dev/null; then
                sudo yum install -y dos2unix jq curl wget rsyslog git -q
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y dos2unix jq curl wget rsyslog git -q
            fi
            ;;
    esac
    
    # Vérifier et démarrer rsyslog
    if command -v systemctl &> /dev/null; then
        sudo systemctl start rsyslog 2>/dev/null || true
        sudo systemctl enable rsyslog 2>/dev/null || true
    fi
    
    success "Dépendances installées"
}

create_directories() {
    section_title "Création de la structure"
    
    info "Création des répertoires système..."
    
    # Répertoires principaux
    mkdir -p "${BASE_DIR}"/{config,dashboards,scripts,archives}
    mkdir -p "${BASE_DIR}/config"/{grafana/provisioning/{datasources,dashboards},prometheus,loki,promtail,influxdb,fluentd}
    
    # Répertoires d'archives
    mkdir -p "${BASE_DIR}/archives"/{rsyslog,fluentd_logs,old_archives}
    
    # Répertoires système
    if ! sudo mkdir -p /var/log/{pfsense,stormshield,paloalto,client_logs} 2>/dev/null; then
        warning "Impossible de créer les répertoires système dans /var/log (permissions?)"
        info "Les logs seront stockés uniquement dans ${BASE_DIR}/archives"
    else
        sudo chmod -R 755 /var/log/{pfsense,stormshield,paloalto,client_logs} 2>/dev/null || true
    fi
    
    # Permissions correctes
    chmod -R 755 "${BASE_DIR}"
    
    success "Structure créée: ${BASE_DIR}"
}

setup_env_file() {
    section_title "Configuration de l'environnement"
    
    if [[ ! -f "${BASE_DIR}/.env" ]]; then
        info "Création du fichier .env..."
        
        if [[ -f "${SCRIPT_DIR}/.env.example" ]]; then
            if ! cp "${SCRIPT_DIR}/.env.example" "${BASE_DIR}/.env" 2>/dev/null; then
                error "Impossible de copier .env.example"
                return 1
            fi
            sed -i "s|BASE_DIR=.*|BASE_DIR=${BASE_DIR}|" "${BASE_DIR}/.env" 2>/dev/null || true
            sed -i "s|ARCHIVES_DIR=.*|ARCHIVES_DIR=${BASE_DIR}/archives|" "${BASE_DIR}/.env" 2>/dev/null || true
            
            # Générer un token InfluxDB aléatoire si vide
            if grep -q "INFLUXDB_INIT_ADMIN_TOKEN=$" "${BASE_DIR}/.env"; then
                info "Génération du token InfluxDB..."
                local influx_token=$(openssl rand -hex 32)
                sed -i "s|INFLUXDB_INIT_ADMIN_TOKEN=|INFLUXDB_INIT_ADMIN_TOKEN=${influx_token}|" "${BASE_DIR}/.env"
                success "Token InfluxDB généré"
            fi
            
            success "Fichier .env créé"
            warning "N'oubliez pas de modifier les mots de passe dans ${BASE_DIR}/.env"
        else
            warning "Fichier .env.example introuvable dans ${SCRIPT_DIR}"
            info "Création d'un fichier .env minimal..."
            local influx_token=$(openssl rand -hex 32)
            cat > "${BASE_DIR}/.env" << EOF
# Configuration HERMES
BASE_DIR=${BASE_DIR}
ARCHIVES_DIR=${BASE_DIR}/archives
INFLUXDB_INIT_ADMIN_TOKEN=${influx_token}
EOF
            success "Fichier .env minimal créé"
        fi
    else
        info "Fichier .env existant conservé"
    fi
}

cleanup_containers() {
    section_title "Nettoyage"
    
    if docker ps -a --filter "name=hermes-" --format "{{.Names}}" | grep -q "hermes-"; then
        info "Nettoyage de l'installation précédente..."
        
        # Arrêter et supprimer les conteneurs
        LAST_LOG=$(mktemp /tmp/hermes_cleanup_XXXX.log)
        docker ps -a --filter "name=hermes-" --format "{{.Names}}" | xargs -r docker stop > "$LAST_LOG" 2>&1
        docker ps -a --filter "name=hermes-" --format "{{.Names}}" | xargs -r docker rm >> "$LAST_LOG" 2>&1
        rm -f "$LAST_LOG"
        unset LAST_LOG
        
        # Supprimer les volumes pour une installation propre
        docker volume rm hermes-grafana-storage hermes-loki-storage hermes-loki-wal hermes-prometheus-storage hermes-influxdb-storage >/dev/null 2>&1 || true
        
        success "Nettoyage terminé"
    else
        info "Aucun conteneur à nettoyer"
        success "Environnement propre"
    fi
}

generate_configs() {
    section_title "Génération des configurations"
    
    info "Copie des fichiers de configuration..."
    
    # Copier tous les fichiers de configuration depuis le repo vers BASE_DIR
    if [[ -d "${SCRIPT_DIR}/config" ]]; then
        cp -r "${SCRIPT_DIR}/config"/* "${BASE_DIR}/config/" 2>/dev/null || true
    fi
    
    # Copier les dashboards
    if [[ -d "${SCRIPT_DIR}/dashboards" ]]; then
        cp -r "${SCRIPT_DIR}/dashboards"/* "${BASE_DIR}/dashboards/" 2>/dev/null || true
    fi
    
    # Copier les scripts
    if [[ -d "${SCRIPT_DIR}/scripts" ]]; then
        cp -r "${SCRIPT_DIR}/scripts"/* "${BASE_DIR}/scripts/" 2>/dev/null || true
        chmod +x "${BASE_DIR}/scripts"/*.sh 2>/dev/null || true
    fi
    
    # Fixer les permissions des volumes Docker
    info "Configuration des permissions des volumes Docker..."
    docker volume create hermes-loki-storage >/dev/null 2>&1 || true
    docker volume create hermes-loki-wal >/dev/null 2>&1 || true
    docker volume create hermes-grafana-storage >/dev/null 2>&1 || true
    docker volume create hermes-prometheus-storage >/dev/null 2>&1 || true
    docker volume create hermes-influxdb-storage >/dev/null 2>&1 || true
    
    # Fixer les permissions avec des conteneurs temporaires
    docker run --rm -v hermes-loki-storage:/data alpine sh -c "chown -R 10001:10001 /data && chmod -R 755 /data" 2>/dev/null || true
    docker run --rm -v hermes-loki-wal:/data alpine sh -c "chown -R 10001:10001 /data && chmod -R 755 /data" 2>/dev/null || true
    docker run --rm -v hermes-grafana-storage:/data alpine sh -c "chown -R 472:472 /data && chmod -R 755 /data" 2>/dev/null || true
    docker run --rm -v hermes-prometheus-storage:/data alpine sh -c "chown -R 65534:65534 /data && chmod -R 755 /data" 2>/dev/null || true
    
    success "Configurations générées"
}

start_services() {
    section_title "Démarrage des services"
    
    cd "${SCRIPT_DIR}"
    
    # Copier docker-compose.yml
    if [[ -f "docker-compose.yml" ]]; then
        cp "docker-compose.yml" "${BASE_DIR}/"
    fi
    
    # Démarrer les services
    cd "${BASE_DIR}"
    info "Démarrage de la stack HERMES..."
    
    LAST_LOG=$(mktemp /tmp/hermes_start_XXXX.log)
    {
        docker compose up -d
    } > "$LAST_LOG" 2>&1 &
    spinner $! "Lancement des conteneurs Docker" || return 1
    rm -f "$LAST_LOG"
    unset LAST_LOG
    
    success "Services démarrés"
}

wait_for_services() {
    section_title "Vérification des services"
    
    info "Attente du démarrage complet..."
    
    local max_wait=60
    local waited=0
    
    while [[ $waited -lt $max_wait ]]; do
        if docker compose ps 2>/dev/null | grep -q "Up\|healthy"; then
            sleep 2
            waited=$((waited + 2))
            progress_bar $waited $max_wait
        else
            break
        fi
    done
    
    echo
    success "Tous les services sont opérationnels"
}

# ══════════════════════════════
# AFFICHAGE FINAL
# ══════════════════════════════

show_final_status() {
    local install_end_time=$(date +%s)
    local duration=$((install_end_time - INSTALL_START_TIME))
    
    # Vérification de l'état des services Docker avant d'afficher le succès
    echo
    info "Vérification de l'état des services Docker..."
    sleep 3  # Attendre que les services démarrent
    
    cd "$BASE_DIR"
    local services_status=$(docker compose ps --format json 2>&1)
    local all_running=true
    
    # Vérifier si tous les services sont en état "running"
    if ! docker compose ps | grep -q "Up"; then
        all_running=false
    fi
    
    if [ "$all_running" = false ]; then
        echo
        error "Certains services Docker ne sont pas démarrés correctement !"
        echo
        warning "État des services :"
        docker compose ps
        echo
        error "Consultez les logs avec : cd $BASE_DIR && docker compose logs"
        echo
        exit 1
    fi
    
    # Si tout est OK, on affiche le résumé avec clear
    clear
    show_banner
    
    section_title "Installation terminée !"
    
    local message="HERMES est maintenant opérationnel !"
    local width=63
    local msg_len=${#message}
    local padding=$(( (width - msg_len) / 2 ))
    local padding_right=$(( width - msg_len - padding ))
    
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    printf "${GREEN}${BOLD}║${NC}%*s${WHITE}${BOLD}%s${NC}%*s${GREEN}${BOLD}║${NC}\n" $padding "" "$message" $padding_right ""
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${CYAN}${BOLD}📊 Accès aux interfaces :${NC}"
    echo
    echo -e "  ${SHIELD} ${BOLD}Grafana${NC}     : ${BLUE}http://127.0.0.1:3000${NC}"
    echo -e "                 ${DIM}Identifiants: ${GREEN}admin${NC} / ${GREEN}admin${NC}${NC}"
    echo
    echo -e "  ${GEAR} ${BOLD}Prometheus${NC}  : ${BLUE}http://127.0.0.1:9090${NC}"
    echo -e "  ${GEAR} ${BOLD}Loki${NC}        : ${BLUE}http://127.0.0.1:3100/ready${NC}"
    echo -e "                 ${DIM}(Pas d'interface web, utiliser via Grafana)${NC}"
    echo
    echo -e "  ${GEAR} ${BOLD}InfluxDB${NC}    : ${BLUE}http://127.0.0.1:8086${NC}"
    echo -e "                 ${DIM}Identifiants: ${GREEN}admin${NC} / ${GREEN}changeme_influx_password${NC}${NC}"
    echo -e "                 ${DIM}Organisation: ${GREEN}hermes${NC} | Bucket: ${GREEN}logs${NC}${NC}"
    echo
    separator
    echo
    echo -e "${YELLOW}${BOLD}⚠️  Actions importantes :${NC}"
    echo
    echo -e "  1. Modifiez les mots de passe dans: ${WHITE}${BASE_DIR}/.env${NC}"
    echo -e "  2. Récupérez le token InfluxDB:     ${WHITE}${BASE_DIR}/scripts/get-influxdb-token.sh${NC}"
    echo -e "  3. Configurez rsyslog:              ${WHITE}sudo systemctl restart rsyslog${NC}"
    echo
    separator
    echo
    echo -e "${CYAN}${BOLD}📁 Installation :${NC} ${WHITE}${BASE_DIR}${NC}"
    echo -e "${CYAN}${BOLD}📝 Logs :${NC} ${WHITE}${LOG_FILE}${NC}"
    echo -e "${CYAN}${BOLD}⏱️  Durée :${NC} ${WHITE}${duration}s${NC}"
    echo
    separator
    echo
    echo -e "${DIM}Pour voir l'état des services: ${WHITE}cd ${BASE_DIR} && docker compose ps${NC}"
    echo
}

# ════════════════════════════
# MENU PRINCIPAL
# ════════════════════════════

show_welcome() {
    show_banner
    
    echo -e "${BOLD}${WHITE}Bienvenue dans l'installateur HERMES !${NC}"
    echo
    echo -e "${CYAN}Ce script va installer et configurer une stack complète de monitoring${NC}"
    echo -e "${CYAN}comprenant Grafana, Prometheus, Loki, InfluxDB et plus encore.${NC}"
    echo
    echo -e "${DIM}Prérequis:${NC}"
    echo -e "  ${CHECKMARK} OS Linux (Debian, Ubuntu, CentOS, RHEL, Fedora)"
    echo -e "  ${CHECKMARK} 4 GB RAM minimum (8 GB recommandé)"
    echo -e "  ${CHECKMARK} 20 GB d'espace disque"
    echo -e "  ${CHECKMARK} Connexion Internet"
    echo
    echo -e "${YELLOW}${BOLD}L'installation prendra environ 5-10 minutes.${NC}"
    echo
    
    read -p "$(echo -e ${GREEN}Appuyez sur Entrée pour continuer...${NC})" 
}

# ══════════════════════════════════
# FONCTION PRINCIPALE
# ══════════════════════════════════

main() {
    # Créer répertoire de base pour les logs
    mkdir -p "${BASE_DIR}"
    touch "$LOG_FILE" 2>/dev/null || true
    
    # Vérifications préalables
    check_whiptail
    check_sudo
    
    # Écran de bienvenue
    show_welcome
    
    # Détection du système
    section_title "Détection du système"
    detect_distro > /dev/null
    show_system_info
    echo
    
    # Installation
    install_docker
    install_dependencies
    
    # Configuration
    create_directories
    setup_env_file
    
    # Nettoyage et génération
    cleanup_containers
    generate_configs
    
    # Démarrage
    start_services
    wait_for_services
    
    # Affichage final
    show_final_status
    
    echo -e "${GREEN}${BOLD}✨ Installation réussie ! ✨${NC}"
    echo
}

# ═══════════════════════════
# POINT D'ENTRÉE
# ═══════════════════════════

# Lancer le script
if ! main "$@"; then
    echo
    error "L'installation a échoué"
    echo -e "${YELLOW}Consultez les logs pour plus de détails${NC}"
    exit 1
fi

exit 0
