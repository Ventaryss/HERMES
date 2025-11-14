#!/bin/bash

# ═══════════════════════════════════════════════════════════════════
# HERMES Agent - Installation Client
# Configure un client pour envoyer logs et métriques vers HERMES
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ══════════════════
# COULEURS
# ══════════════════

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'

# ════════════════════════════════════
# FONCTIONS D'AFFICHAGE
# ════════════════════════════════════

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
    ╔═════════════════════════════════════════════════════════╗
    ║                                                         ║
    ║              HERMES - Agent Installation                ║
    ║                                                         ║
    ║          Configuration de monitoring client             ║
    ║                                                         ║
    ╚═════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

info() {
    echo -e "${BLUE}[ℹ]${NC} ${1}"
}

success() {
    echo -e "${GREEN}[✓]${NC} ${GREEN}${1}${NC}"
}

warning() {
    echo -e "${YELLOW}[!]${NC} ${YELLOW}${1}${NC}"
}

error() {
    echo -e "${RED}[✗]${NC} ${RED}${1}${NC}" >&2
}

separator() {
    echo -e "${DIM}─────────────────────────────────────────────────────────${NC}"
}

section() {
    echo
    echo -e "${BOLD}${CYAN}▶ ${1}${NC}"
    separator
}

# ══════════════════════════════════════
# DÉTECTION SYSTÈME AVANCÉE
# ══════════════════════════════════════

# Variables globales
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
            DISTRO_VERSION="12"
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
    
    # Cas spécial Debian 13 (Trixie)
    if [[ "$DISTRO_BASE" == "debian" ]] && [[ "$DISTRO_VERSION" == "13" || "$DISTRO_CODENAME" == "trixie" ]]; then
        warning "Debian 13 (Trixie) détecté - utilisation Bookworm pour compatibilité"
        DISTRO_CODENAME="bookworm"
        DISTRO_VERSION="12"
    fi
    
    echo "$DISTRO_BASE"
}

# ═══════════════════════
# VALIDATION IP
# ═══════════════════════

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

get_server_ip() {
    if [[ -n "${SERVER_IP:-}" ]]; then
        info "Utilisation de SERVER_IP: ${BOLD}${SERVER_IP}${NC}"
        return 0
    fi
    
    echo
    echo -e "${CYAN}${BOLD}╔═════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  Configuration du serveur HERMES              ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚═════════════════════════════════════════════════╝${NC}"
    echo
    
    while true; do
        read -p "$(echo -e ${WHITE}Adresse IP du serveur HERMES: ${NC})" SERVER_IP
        
        if [[ -z "$SERVER_IP" ]]; then
            error "L'adresse IP est requise"
            continue
        fi
        
        if validate_ip "$SERVER_IP"; then
            success "IP valide: ${SERVER_IP}"
            break
        else
            warning "Format d'IP invalide. Exemple: 192.168.1.100"
        fi
    done
}

# ═════════════════════════════════════════
# INSTALLATION NODE EXPORTER
# ═════════════════════════════════════════

install_node_exporter() {
    section "Installation de Node Exporter"
    
    if systemctl is-active --quiet node_exporter 2>/dev/null; then
        success "Node Exporter déjà installé et actif"
        return 0
    fi
    
    local version="1.7.0"
    local filename="node_exporter-${version}.linux-amd64.tar.gz"
    
    info "Téléchargement de Node Exporter v${version}..."
    cd /tmp
    curl -sL "https://github.com/prometheus/node_exporter/releases/download/v${version}/${filename}" -o "${filename}"
    
    info "Extraction..."
    tar xzf "${filename}" >/dev/null 2>&1
    
    info "Installation du binaire..."
    sudo mv "node_exporter-${version}.linux-amd64/node_exporter" /usr/local/bin/
    sudo chown root:root /usr/local/bin/node_exporter
    sudo chmod +x /usr/local/bin/node_exporter
    
    rm -rf "node_exporter-${version}.linux-amd64"*
    
    if ! id -u node_exporter &>/dev/null; then
        sudo useradd --no-create-home --shell /bin/false node_exporter
    fi
    
    info "Création du service systemd..."
    sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target

[Service]
Type=simple
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter \
    --collector.filesystem.mount-points-exclude='^/(dev|proc|sys|var/lib/docker/.+)($|/)' \
    --collector.netclass.ignored-devices='^(veth.*|br.*|docker.*|lo)$'
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl start node_exporter
    sudo systemctl enable node_exporter >/dev/null 2>&1
    
    success "Node Exporter installé et démarré sur le port 9100"
}

# ══════════════════════════════════
# CONFIGURATION RSYSLOG
# ══════════════════════════════════

config_rsyslog() {
    section "Configuration de Rsyslog"
    
    if ! command -v rsyslogd &> /dev/null; then
        info "Installation de rsyslog..."
        
        case "$DISTRO_FAMILY" in
            debian)
                sudo apt-get update -qq
                sudo apt-get install -y rsyslog -qq
                ;;
            rhel)
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y rsyslog -q
                else
                    sudo yum install -y rsyslog -q
                fi
                ;;
            arch)
                sudo pacman -Sy --noconfirm rsyslog
                ;;
            suse)
                sudo zypper install -y rsyslog
                ;;
            *)
                error "Distribution non supportée: $DISTRO_FAMILY"
                return 1
                ;;
        esac
        
        success "Rsyslog installé"
    else
        info "Rsyslog déjà installé"
    fi
    
    info "Configuration du transfert de logs..."
    
    sudo tee /etc/rsyslog.d/50-hermes-client.conf > /dev/null << EOF
# ═════════════════════════════════════════════════════════════════
# Configuration Rsyslog - HERMES Client
# ═════════════════════════════════════════════════════════════════

template(name="HermesJSONFormat" type="list") {
    constant(value="{")
    constant(value="\"timestamp\":\"")
    property(name="timereported" dateFormat="rfc3339")
    constant(value="\",\"host\":\"")
    property(name="hostname")
    constant(value="\",\"program\":\"")
    property(name="programname")
    constant(value="\",\"severity\":\"")
    property(name="syslogseverity-text")
    constant(value="\",\"facility\":\"")
    property(name="syslogfacility-text")
    constant(value="\",\"pid\":\"")
    property(name="procid")
    constant(value="\",\"message\":\"")
    property(name="msg" format="json")
    constant(value="\",\"source\":\"hermes-client\"")
    constant(value="\"}\n")
}

*.* action(
    type="omfwd"
    target="${SERVER_IP}"
    port="514"
    protocol="tcp"
    template="HermesJSONFormat"
    queue.type="LinkedList"
    queue.size="10000"
    queue.filename="hermes_queue"
    queue.saveOnShutdown="on"
    queue.maxDiskSpace="100m"
    action.resumeRetryCount="-1"
    action.resumeInterval="30"
)
EOF
    
    sudo systemctl restart rsyslog
    
    success "Rsyslog configuré pour transmettre vers ${SERVER_IP}:514"
}

# ═══════════════════════════════
# MENU DE SÉLECTION
# ═══════════════════════════════

show_component_menu() {
    echo
    echo -e "${CYAN}${BOLD}╔═════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  Composants à installer                        ${CYAN}${BOLD}║${NC}"
    echo -e "${CYAN}${BOLD}╚═════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "  ${WHITE}1)${NC} Rsyslog uniquement ${DIM}(transfert de logs)${NC}"
    echo -e "  ${WHITE}2)${NC} Node Exporter uniquement ${DIM}(métriques système)${NC}"
    echo -e "  ${WHITE}3)${NC} Les deux ${GREEN}${BOLD}(recommandé)${NC}"
    echo
    
    while true; do
        read -p "$(echo -e ${WHITE}Votre choix [1-3]: ${NC})" choice
        
        case $choice in
            1|2|3)
                echo "$choice"
                return 0
                ;;
            *)
                warning "Veuillez choisir 1, 2 ou 3"
                ;;
        esac
    done
}

# ══════════════════════════════════
# VÉRIFICATION ET TESTS
# ══════════════════════════════════

verify_installation() {
    section "Vérification de l'installation"
    
    local all_ok=true
    
    if [[ $INSTALL_CHOICE == "1" ]] || [[ $INSTALL_CHOICE == "3" ]]; then
        if sudo systemctl is-active --quiet rsyslog; then
            success "Rsyslog: actif"
        else
            error "Rsyslog: inactif"
            all_ok=false
        fi
    fi
    
    if [[ $INSTALL_CHOICE == "2" ]] || [[ $INSTALL_CHOICE == "3" ]]; then
        if systemctl is-active --quiet node_exporter; then
            success "Node Exporter: actif"
        else
            error "Node Exporter: inactif"
            all_ok=false
        fi
    fi
    
    if $all_ok; then
        success "Tous les services sont opérationnels"
    else
        warning "Certains services nécessitent attention"
    fi
}

# ══════════════════════════════
# AFFICHAGE FINAL
# ══════════════════════════════

show_final_status() {
    clear
    show_banner
    
    echo -e "${GREEN}${BOLD}╔═════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║${NC}  ${WHITE}Installation terminée avec succès !${NC}            ${GREEN}${BOLD}║${NC}"
    echo -e "${GREEN}${BOLD}╚═════════════════════════════════════════════════╝${NC}"
    echo
    
    separator
    echo
    echo -e "${CYAN}${BOLD}📡 Configuration :${NC}"
    echo
    echo -e "  ${WHITE}Serveur HERMES:${NC} ${CYAN}${SERVER_IP}${NC}"
    
    if [[ $INSTALL_CHOICE == "1" ]] || [[ $INSTALL_CHOICE == "3" ]]; then
        echo -e "  ${WHITE}Logs envoyés vers:${NC} ${CYAN}${SERVER_IP}:514${NC}"
    fi
    
    if [[ $INSTALL_CHOICE == "2" ]] || [[ $INSTALL_CHOICE == "3" ]]; then
        local ip=$(hostname -I | awk '{print $1}')
        echo -e "  ${WHITE}Métriques sur:${NC} ${CYAN}http://${ip}:9100/metrics${NC}"
    fi
    
    echo
    separator
    echo
    echo -e "${YELLOW}${BOLD}📝 Prochaines étapes :${NC}"
    echo
    
    if [[ $INSTALL_CHOICE == "2" ]] || [[ $INSTALL_CHOICE == "3" ]]; then
        echo -e "  1. Ajoutez ce client dans Prometheus sur ${SERVER_IP}"
        echo -e "     ${DIM}Éditez: ~/HERMES/config/prometheus/prometheus.yml${NC}"
        local ip=$(hostname -I | awk '{print $1}')
        echo -e "     ${DIM}Target: ${ip}:9100${NC}"
    fi
    
    if [[ $INSTALL_CHOICE == "1" ]] || [[ $INSTALL_CHOICE == "3" ]]; then
        echo -e "  2. Testez l'envoi de logs:"
        echo -e "     ${WHITE}logger -t test \"Message de test HERMES\"${NC}"
    fi
    
    echo
    separator
    echo
    echo -e "${DIM}Vérifier les services:${NC}"
    
    if [[ $INSTALL_CHOICE == "1" ]] || [[ $INSTALL_CHOICE == "3" ]]; then
        echo -e "  ${WHITE}sudo systemctl status rsyslog${NC}"
    fi
    
    if [[ $INSTALL_CHOICE == "2" ]] || [[ $INSTALL_CHOICE == "3" ]]; then
        echo -e "  ${WHITE}sudo systemctl status node_exporter${NC}"
    fi
    
    echo
}

# ══════════════════════════════════
# FONCTION PRINCIPALE
# ══════════════════════════════════

main() {
    show_banner
    
    # Vérifications
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        warning "Ce script nécessite sudo"
        sudo -v || { error "Permissions sudo requises"; exit 1; }
    fi
    
    # Détection système
    detect_distro > /dev/null
    info "Distribution: ${BOLD}${DISTRO_BASE} ${DISTRO_VERSION}${NC} (Famille: ${DISTRO_FAMILY})"
    echo
    
    # Configuration
    get_server_ip
    INSTALL_CHOICE=$(show_component_menu)
    
    echo
    info "Installation des composants sélectionnés..."
    echo
    
    # Installation selon le choix
    case $INSTALL_CHOICE in
        1)
            config_rsyslog
            ;;
        2)
            install_node_exporter
            ;;
        3)
            config_rsyslog
            install_node_exporter
            ;;
    esac
    
    # Vérification
    verify_installation
    
    # Affichage final
    show_final_status
    
    echo -e "${GREEN}${BOLD}✨ Configuration terminée ! ✨${NC}"
    echo
}

# ═══════════════════════════
# POINT D'ENTRÉE
# ═══════════════════════════

trap 'error "Installation interrompue"; exit 130' INT TERM

main "$@"

exit 0
