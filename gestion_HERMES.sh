#!/bin/bash

# ------------------------------------------------------
# HERMES - Plateforme de monitoring centralisé
# Script de gestion et d'installation
# ------------------------------------------------------

set -Eeuo pipefail

# ----------------------------------------
# COULEURS THÈME HERMES (Cyan/Blue)
# ----------------------------------------
# Note: Pas de readonly car helpers.sh peut aussi les définir

RED='\033[0;31m'
BRIGHT_RED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'              # Couleur principale HERMES
BRIGHT_CYAN='\033[1;36m'       # Cyan clair
DARK_CYAN='\033[38;5;31m'      # Cyan foncé
SKY_BLUE='\033[38;5;117m'      # Bleu ciel
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

BOLD='\033[1m'
DIM='\033[2m'

# Symboles
CHECKMARK="✓"
CROSS="✗"
ARROW="→"
GEAR="⚙"
ROCKET="🚀"
SHIELD="🛡️"

# -----------------------
# GESTION DES ERREURS
# -----------------------

handle_error() {
    local exit_code=$1
    local line_number=$2
    
    local message="  Une erreur est survenue"
    local width=47
    local msg_len=${#message}
    local padding=$(( (width - msg_len) / 2 ))
    local padding_right=$(( width - msg_len - padding ))
    
    echo
    echo -e "${RED}${BOLD}╔═══════════════════════════════════════════════╗${NC}"
    printf "${RED}${BOLD}║${NC}%*s${WHITE}%s${NC}%*s${RED}${BOLD}║${NC}\n" $padding "" "$message" $padding_right ""
    echo -e "${RED}${BOLD}╚═══════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Code d'erreur:${NC} $exit_code"
    echo -e "${YELLOW}Ligne:${NC} $line_number"
    echo
    
    if [ -n "${LAST_LOG:-}" ] && [ -f "$LAST_LOG" ]; then
        echo -e "${YELLOW}${BOLD}═══ Dernières lignes du log ═══${NC}"
        tail -n 30 "$LAST_LOG" 2>/dev/null || true
        echo -e "${YELLOW}${BOLD}═══════════════════════════════${NC}"
        echo
    fi
    
    exit $exit_code
}

trap 'handle_error $? $LINENO' ERR INT TERM

# Vérifier sudo (interdit root direct)
if [ "$(id -u)" -eq 0 ] && [ -z "$SUDO_USER" ]; then
    echo -e "\n${RED}Ce script ne doit pas être lancé en root direct.${NC}"
    echo -e "${YELLOW}👉 Utilisez un utilisateur normal avec sudo :${NC}"
    echo -e "   ${WHITE}sudo ./gestion_HERMES.sh${NC}\n"
    exit 1
fi

# Identifier l'utilisateur réel
if [ -z "${SUDO_USER:-}" ]; then
    SUDO_USER=$(logname 2>/dev/null || echo "$USER")
fi

# Identifier le répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="$SCRIPT_DIR"
export HERMES_BASE_DIR="$SCRIPT_DIR"

# Charger les helpers et modules
source "${SCRIPT_DIR}/scripts/helpers.sh"
source "${SCRIPT_DIR}/modules/core.sh"
source "${SCRIPT_DIR}/modules/dashboards.sh"
source "${SCRIPT_DIR}/modules/health.sh"
source "${SCRIPT_DIR}/modules/backup.sh"
source "${SCRIPT_DIR}/modules/logs.sh"
source "${SCRIPT_DIR}/modules/sources.sh"
source "${SCRIPT_DIR}/modules/credentials.sh"

# Détecter la commande Docker Compose disponible
detect_docker_compose_cmd() {
    if docker compose version &>/dev/null; then
        echo "docker compose"
    elif docker-compose --version &>/dev/null; then
        echo "docker-compose"
    else
        echo ""
    fi
}
DOCKER_COMPOSE_CMD=""

# Détecter la distribution système
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_VERSION=$VERSION_ID
else
    DISTRO="unknown"
    DISTRO_VERSION="unknown"
fi

# -------------------------
# FONCTIONS D'AFFICHAGE
# -------------------------

# Titre de section
section_title() {
    local title="$1"
    local width=55
    local title_len=${#title}
    local padding=$(( (width - title_len) / 2 ))
    local padding_right=$(( width - title_len - padding ))
    
    echo
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    printf "${BOLD}${CYAN}║${NC}%*s${BOLD}${WHITE}%s${NC}%*s${BOLD}${CYAN}║${NC}\n" $padding "" "$title" $padding_right ""
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
}

# Messages colorés
info() {
    echo -e "${BLUE}[INFO]${NC} ${1}"
}

success() {
    echo -e "${GREEN}[${CHECKMARK}]${NC} ${GREEN}${1}${NC}"
}

warning() {
    echo -e "${YELLOW}[!]${NC} ${YELLOW}${1}${NC}"
}

error() {
    echo -e "${RED}[${CROSS}]${NC} ${RED}${1}${NC}" >&2
}

# Spinner d'attente avec gestion d'erreur
spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${BRIGHT_CYAN}${spin:$i:1}${NC} ${message}"
        sleep 0.1
    done
    
    wait $pid
    local rc=$?
    
    if [ $rc -eq 0 ]; then
        printf "\r${GREEN}${CHECKMARK}${NC} ${message}\n"
        return 0
    else
        printf "\r${RED}${CROSS}${NC} ${message}\n"
        error "La commande a échoué avec le code: $rc"
        
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

# Barre de progression
progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r\033[K"
    
    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    
    printf "${CYAN}[${bar}]${NC} ${WHITE}%3d%%${NC}" "$percentage"
}

# Exécuter une commande avec spinner
run_with_loader() {
    local message="$1"; shift
    LAST_LOG=$(mktemp /tmp/hermes_run_XXXX.log)
    
    # Lancer la commande et capturer la sortie
    "$@" > "$LAST_LOG" 2>&1 &
    local pid=$!
    
    # Utiliser le spinner
    spinner $pid "$message" || return 1
    
    # Nettoyer si succès
    rm -f "$LAST_LOG"
    unset LAST_LOG
    return 0
}

# Affichage titre/menu
display_title_menu() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
    ╔════════════════════════════════════════════════════════════════╗
    ║                                                                ║
    ║      ██╗  ██╗███████╗██████╗ ███╗   ███╗███████╗███████╗       ║
    ║      ██║  ██║██╔════╝██╔══██╗████╗ ████║██╔════╝██╔════╝       ║
    ║      ███████║█████╗  ██████╔╝██╔████╔██║█████╗  ███████╗       ║
    ║      ██╔══██║██╔══╝  ██╔══██╗██║╚██╔╝██║██╔══╝  ╚════██║       ║
    ║      ██║  ██║███████╗██║  ██║██║ ╚═╝ ██║███████╗███████║       ║
    ║      ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝       ║
    ║                                                                ║
    ║    Highly Efficient Real-time Monitoring and Event System      ║
    ║                                                                ║
    ╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${SKY_BLUE}${BOLD}     Plateforme de monitoring centralisé${NC} ${DIM}• Logs • Métriques • Alertes${NC}"
    echo
    echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────────────────────${NC}"
    echo
    
    echo -e "${BRIGHT_CYAN}${BOLD}🚀 INSTALLATION & CONFIGURATION${NC}"
    echo -e "  ${WHITE}1${NC}  Installation complète ${DIM}(Docker + dépendances + stack)${NC}"
    echo -e "  ${WHITE}2${NC}  Installation rapide ${DIM}(sans dépendances système)${NC}"
    echo -e "  ${WHITE}3${NC}  Démarrer la stack HERMES"
    echo -e "  ${WHITE}4${NC}  Arrêter la stack HERMES"
    echo -e "  ${WHITE}5${NC}  Redémarrer la stack"
    echo -e "  ${WHITE}6${NC}  Afficher l'état des services"
    echo
    
    echo -e "${BRIGHT_CYAN}${BOLD}📊 DASHBOARDS GRAFANA${NC}"
    echo -e "  ${WHITE}7${NC}  Lister les dashboards"
    echo -e "  ${WHITE}8${NC}  Importer un dashboard ${DIM}(fichier JSON local)${NC}"
    echo -e "  ${WHITE}9${NC}  Installer dashboard depuis templates/"
    echo -e "  ${WHITE}10${NC} Exporter un dashboard existant"
    echo -e "  ${WHITE}11${NC} Recharger Grafana"
    echo
    
    echo -e "${BRIGHT_CYAN}${BOLD}💾 BACKUPS & LOGS${NC}"
    echo -e "  ${WHITE}12${NC} Sauvegarde complète ${DIM}(config + volumes)${NC}"
    echo -e "  ${WHITE}13${NC} Sauvegarde configuration uniquement"
    echo -e "  ${WHITE}14${NC} Sauvegarde volumes Docker uniquement"
    echo -e "  ${WHITE}15${NC} Suivre les logs d'un service"
    echo -e "  ${WHITE}16${NC} Exporter tous les logs Docker"
    echo
    
    echo -e "${BRIGHT_CYAN}${BOLD}💉 HEALTHCHECK & DIAGNOSTIC${NC}"
    echo -e "  ${WHITE}17${NC} Vérifier la santé des services"
    echo -e "  ${WHITE}18${NC} Vérifier les ports critiques"
    echo -e "  ${WHITE}19${NC} Diagnostic complet système"
    echo
    
    echo -e "${BRIGHT_CYAN}${BOLD}📡 SOURCES DE LOGS${NC}"
    echo -e "  ${WHITE}20${NC} Lister les sources configurées"
    echo -e "  ${WHITE}21${NC} Ajouter une nouvelle source ${DIM}(firewall, serveur, app...)${NC}"
    echo -e "  ${WHITE}22${NC} Supprimer une source"
    echo -e "  ${WHITE}23${NC} Appliquer les changements ${DIM}(redémarrer services)${NC}"
    echo -e "  ${WHITE}24${NC} Guide de configuration ${DIM}(aide)${NC}"
    echo
    
    echo -e "${BRIGHT_CYAN}${BOLD}🔐 GESTION DES CREDENTIALS${NC}"
    echo -e "  ${WHITE}25${NC} Afficher les credentials ${DIM}(masqués)${NC}"
    echo -e "  ${WHITE}26${NC} Révéler les credentials ${DIM}(en clair)${NC}"
    echo -e "  ${WHITE}27${NC} Regénérer tous les mots de passe"
    echo -e "  ${WHITE}28${NC} Changer un mot de passe spécifique"
    echo -e "  ${WHITE}29${NC} Exporter les credentials vers un fichier"
    echo
    
    echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────────────────────${NC}"
    echo
    
    # Détecter les informations système
    local docker_status="N/A"
    if command -v docker &>/dev/null; then
        docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "N/A")
        docker_status="Docker ${docker_version}"
    fi
    
    local compose_cmd=$(detect_docker_compose_cmd)
    if [ -z "$compose_cmd" ]; then
        compose_cmd="N/A"
    fi
    
    echo -e "${SKY_BLUE}🖥️  Système:${NC} ${WHITE}${DISTRO^} ${DISTRO_VERSION}${NC} ${SKY_BLUE}|${NC} ${WHITE}${docker_status}${NC} ${SKY_BLUE}|${NC} ${WHITE}${compose_cmd}${NC}"
    echo
    
    read -p "$(echo -e ${CYAN}${BOLD}👉 Entrez votre choix [1-29, 0=quitter]: ${NC})" choice
    echo
    
    return 0
}

# Diagnostic complet
diagnostic_complet() {
    section_title "Diagnostic complet du système HERMES"
    
    echo -e "${CYAN}${BOLD}═══ Système ═══${NC}"
    echo -e "Distribution: ${WHITE}${DISTRO^} ${DISTRO_VERSION}${NC}"
    echo -e "Kernel: ${WHITE}$(uname -r)${NC}"
    echo -e "Uptime: ${WHITE}$(uptime -p)${NC}"
    echo
    
    echo -e "${CYAN}${BOLD}═══ Docker ═══${NC}"
    if command -v docker &>/dev/null; then
        echo -e "Version: ${WHITE}$(docker --version)${NC}"
        echo -e "Status: ${GREEN}Installé${NC}"
        echo -e "Compose: ${WHITE}$(detect_docker_compose_cmd)${NC}"
    else
        echo -e "Status: ${RED}Non installé${NC}"
    fi
    echo
    
    echo -e "${CYAN}${BOLD}═══ Ports critiques ═══${NC}"
    local ports=("3000:Grafana" "9090:Prometheus" "3100:Loki" "8086:InfluxDB" "9100:Node-Exporter")
    for entry in "${ports[@]}"; do
        local p="${entry%%:*}"
        local label="${entry##*:}"
        if ss -lnt 2>/dev/null | grep -q ":$p " || lsof -iTCP:"$p" -sTCP:LISTEN &>/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} Port ${WHITE}${p}${NC} (${label}) ${GREEN}en écoute${NC}"
        else
            echo -e "  ${YELLOW}○${NC} Port ${WHITE}${p}${NC} (${label}) ${GRAY}non utilisé${NC}"
        fi
    done
    echo
    
    echo -e "${CYAN}${BOLD}═══ Fichiers de configuration ═══${NC}"
    local files=("docker-compose.yml" ".env" "config/grafana" "config/prometheus" "config/loki")
    for f in "${files[@]}"; do
        if [ -e "${HERMES_BASE_DIR}/${f}" ]; then
            echo -e "  ${GREEN}✓${NC} ${WHITE}${f}${NC}"
        else
            echo -e "  ${RED}✗${NC} ${WHITE}${f}${NC} ${RED}(manquant)${NC}"
        fi
    done
    echo
    
    echo -e "${CYAN}${BOLD}═══ Volumes Docker ═══${NC}"
    local vol_count=$(docker volume ls --format '{{.Name}}' 2>/dev/null | grep -c -E '(hermes|HERMES)' || echo "0")
    echo -e "Volumes HERMES détectés: ${WHITE}${vol_count}${NC}"
    if [ "$vol_count" -gt 0 ]; then
        docker volume ls --format 'table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}' 2>/dev/null | grep -E '(NAME|hermes|HERMES)' || true
    fi
    echo
    
    echo -e "${CYAN}${BOLD}═══ Services Docker ═══${NC}"
    if [ -f "${HERMES_BASE_DIR}/docker-compose.yml" ]; then
        cd "$HERMES_BASE_DIR"
        local compose_cmd=$(detect_docker_compose_cmd)
        if [ -n "$compose_cmd" ]; then
            $compose_cmd ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo "Aucun service en cours"
        fi
    else
        echo -e "${YELLOW}docker-compose.yml introuvable${NC}"
    fi
    echo
}

# Installation rapide (sans dépendances)
quick_install() {
    section_title "Installation rapide HERMES"
    
    info "Cette option suppose que Docker est déjà installé"
    echo
    
    # Vérifier Docker
    if ! command -v docker &>/dev/null; then
        error "Docker n'est pas installé. Utilisez l'option 1 (installation complète)"
        return 1
    fi
    
    # Détecter compose
    DOCKER_COMPOSE_CMD=$(detect_docker_compose_cmd)
    if [ -z "$DOCKER_COMPOSE_CMD" ]; then
        error "Docker Compose introuvable"
        return 1
    fi
    
    success "Docker détecté: $(docker --version)"
    success "Compose détecté: ${DOCKER_COMPOSE_CMD}"
    echo
    
    # Configurer .env
    core_setup_env
    
    # Vérifier les ports
    core_check_ports
    
    # Démarrer
    core_start_stack
    
    success "Installation rapide terminée !"
    echo
    info "Accédez à Grafana: ${WHITE}http://localhost:3000${NC}"
    info "Accédez à Prometheus: ${WHITE}http://localhost:9090${NC}"
    echo
}

# Afficher le résumé après démarrage
show_startup_summary() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
    ╔════════════════════════════════════════════════════════════════╗
    ║                                                                ║
    ║                  ✨ HERMES EST OPÉRATIONNEL ✨                 ║
    ║                                                                ║
    ╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Lire les vrais credentials depuis .env
    local grafana_user=$(grep "^GRAFANA_ADMIN_USER=" "${HERMES_BASE_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "admin")
    local grafana_pass=$(grep "^GRAFANA_ADMIN_PASSWORD=" "${HERMES_BASE_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "admin")
    local influx_user=$(grep "^INFLUXDB_INIT_USERNAME=" "${HERMES_BASE_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "admin")
    local influx_pass=$(grep "^INFLUXDB_INIT_PASSWORD=" "${HERMES_BASE_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "adminadmin123")
    
    echo -e "${CYAN}${BOLD}📊 Accès aux interfaces de monitoring :${NC}"
    echo
    echo -e "  ${SHIELD} ${BOLD}Grafana${NC}       : ${SKY_BLUE}http://127.0.0.1:3000${NC}"
    echo -e "                   ${DIM}Identifiants: ${GREEN}${grafana_user}${NC} / ${GREEN}${grafana_pass}${NC}"
    echo -e "                   ${DIM}(💾 Notez ces credentials maintenant !)${NC}"
    echo
    echo -e "  ${GEAR} ${BOLD}Prometheus${NC}    : ${SKY_BLUE}http://127.0.0.1:9090${NC}"
    echo -e "                   ${DIM}(Métriques temps réel)${NC}"
    echo
    echo -e "  ${GEAR} ${BOLD}Loki${NC}          : ${SKY_BLUE}http://127.0.0.1:3100/ready${NC}"
    echo -e "                   ${DIM}(API logs - utiliser via Grafana)${NC}"
    echo
    echo -e "  ${GEAR} ${BOLD}InfluxDB${NC}      : ${SKY_BLUE}http://127.0.0.1:8086${NC}"
    echo -e "                   ${DIM}Identifiants: ${GREEN}${influx_user}${NC} / ${GREEN}${influx_pass}${NC}"
    echo -e "                   ${DIM}Organisation: ${GREEN}hermes${NC} | Bucket: ${GREEN}logs${NC}"
    echo
    echo -e "  ${GEAR} ${BOLD}Node Exporter${NC} : ${SKY_BLUE}http://127.0.0.1:9100${NC}"
    echo -e "                   ${DIM}(Métriques système)${NC}"
    echo
    
    # Wazuh (si disponible dans .env)
    local wazuh_dash_user=$(grep "^WAZUH_DASHBOARD_USER=" "${HERMES_BASE_DIR}/.env" 2>/dev/null | cut -d'=' -f2)
    local wazuh_dash_pass=$(grep "^WAZUH_DASHBOARD_PASSWORD=" "${HERMES_BASE_DIR}/.env" 2>/dev/null | cut -d'=' -f2)
    
    if [[ -n "$wazuh_dash_user" ]]; then
        echo -e "  ${SHIELD} ${BOLD}Wazuh Security${NC} : ${SKY_BLUE}http://127.0.0.1:5601${NC}"
        echo -e "                   ${DIM}Identifiants: ${GREEN}${wazuh_dash_user}${NC} / ${GREEN}${wazuh_dash_pass}${NC}"
        echo -e "                   ${DIM}(Plateforme de sécurité & SIEM)${NC}"
        echo
    fi
    
    echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────────────────────${NC}"
    echo
    echo -e "${YELLOW}${BOLD}📝 Prochaines étapes recommandées :${NC}"
    echo
    echo -e "  ${WHITE}1.${NC} ${YELLOW}IMPORTANT${NC}: Sauvegardez vos credentials ${CYAN}(option 25-26 du menu)${NC}"
    echo -e "  ${WHITE}2.${NC} Connectez-vous à Grafana avec les identifiants ci-dessus"
    echo -e "  ${WHITE}3.${NC} Ajoutez vos sources de logs ${CYAN}(option 21 du menu)${NC}"
    echo -e "      ${DIM}→ Firewalls, serveurs Linux, applications, Docker...${NC}"
    echo -e "  ${WHITE}4.${NC} Importez des dashboards via le menu (option 7-9)"
    echo
    echo -e "${CYAN}${BOLD}─────────────────────────────────────────────────────────────────────${NC}"
    echo
    echo -e "${DIM}💡 Astuces utiles :${NC}"
    echo -e "   ${DIM}• Option 19 : Diagnostic complet du système${NC}"
    echo -e "   ${DIM}• Option 25 : Voir tous les credentials${NC}"
    echo -e "   ${DIM}• Option 27 : Regénérer les mots de passe si oubliés${NC}"
    echo
}

# Confirmation avant action
confirm_action() {
    local action="$1"
    local description="$2"
    
    echo
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Action: ${WHITE}${action}${NC}"
    echo -e "${DIM}${description}${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Boucle principale du menu
main_loop() {
    while true; do
        display_title_menu
        
        case "$choice" in
            1)
                # Installation complète
                confirm_action "Installation complète HERMES" \
                    "Cette option va installer Docker, les dépendances système, configurer\nles fichiers et démarrer toute la stack de monitoring."
                core_full_install
                show_startup_summary
                ;;
            2)
                # Installation rapide
                confirm_action "Installation rapide" \
                    "Installation simplifiée supposant que Docker est déjà installé.\nConfigure et démarre uniquement la stack HERMES."
                quick_install
                show_startup_summary
                ;;
            3)
                # Démarrer
                confirm_action "Démarrage de la stack HERMES" \
                    "Démarre tous les conteneurs Docker: Grafana, Prometheus, Loki,\nInfluxDB, Promtail et Node Exporter."
                core_start_stack
                show_startup_summary
                ;;
            4)
                # Arrêter
                confirm_action "Arrêt de la stack HERMES" \
                    "Arrête tous les conteneurs Docker en préservant les données."
                core_stop_stack
                ;;
            5)
                # Redémarrer
                confirm_action "Redémarrage de la stack" \
                    "Arrête puis redémarre tous les conteneurs pour appliquer\nles changements de configuration."
                core_restart_stack
                show_startup_summary
                ;;
            6)
                # Status
                confirm_action "État des services" \
                    "Affiche l'état actuel de tous les conteneurs Docker HERMES."
                core_status
                ;;
            7)
                # Lister dashboards
                confirm_action "Liste des dashboards Grafana" \
                    "Affiche tous les dashboards actuellement disponibles dans Grafana."
                dash_list_dashboards
                ;;
            8)
                # Importer dashboard
                confirm_action "Import de dashboard" \
                    "Importe un dashboard Grafana depuis un fichier JSON local."
                dash_interactive_import
                ;;
            9)
                # Installer template
                confirm_action "Installation depuis templates" \
                    "Installe un dashboard pré-configuré depuis le dossier templates/."
                dash_install_template
                ;;
            10)
                # Exporter dashboard
                confirm_action "Export de dashboard" \
                    "Exporte un dashboard Grafana existant vers un fichier JSON."
                dash_export_dashboard
                ;;
            11)
                # Recharger Grafana
                confirm_action "Redémarrage Grafana" \
                    "Redémarre uniquement le service Grafana pour appliquer les changements."
                dash_reload_grafana
                ;;
            12)
                # Backup complet
                confirm_action "Sauvegarde complète" \
                    "Sauvegarde la configuration ET tous les volumes Docker\n(peut prendre plusieurs minutes)."
                backup_all
                success "Sauvegarde terminée avec succès !"
                info "Localisation: ${WHITE}${HERMES_BASE_DIR}/backups/${NC}"
                ;;
            13)
                # Backup config
                confirm_action "Sauvegarde configuration" \
                    "Sauvegarde uniquement les fichiers de configuration\n(docker-compose.yml, .env, config/, dashboards/)."
                backup_config
                ;;
            14)
                # Backup volumes
                confirm_action "Sauvegarde volumes Docker" \
                    "Sauvegarde tous les volumes Docker contenant les données\n(bases de données, métriques, logs)."
                backup_volumes
                ;;
            15)
                # Logs service
                confirm_action "Logs en temps réel" \
                    "Affiche les logs d'un service spécifique en temps réel\n(Ctrl+C pour quitter)."
                logs_tail_service
                ;;
            16)
                # Export logs
                confirm_action "Export global des logs" \
                    "Exporte tous les logs Docker dans un fichier texte unique."
                logs_export_all
                ;;
            17)
                # Health check
                confirm_action "Vérification de santé" \
                    "Vérifie l'état de santé de chaque service (healthchecks)."
                health_check_services
                ;;
            18)
                # Ports check
                confirm_action "Vérification des ports" \
                    "Vérifie que tous les ports critiques sont bien en écoute."
                health_ports
                ;;
            19)
                # Diagnostic complet
                confirm_action "Diagnostic complet système" \
                    "Effectue un diagnostic approfondi de toute l'installation HERMES."
                diagnostic_complet
                ;;
            20)
                # Lister sources
                confirm_action "Liste des sources de logs" \
                    "Affiche toutes les sources configurées (firewalls, serveurs, applications...)."
                sources_list
                ;;
            21)
                # Ajouter source
                confirm_action "Ajout d'une source de logs" \
                    "Configuration interactive d'une nouvelle source de logs.\nSupporte: firewalls, serveurs Linux, applications, Docker.\nFormats personnalisés acceptés."
                sources_add
                success "N'oubliez pas d'appliquer les changements (option 23) !"
                ;;
            22)
                # Supprimer source
                confirm_action "Suppression d'une source" \
                    "Supprime une source de logs et sa configuration associée."
                sources_remove
                ;;
            23)
                # Appliquer changements
                confirm_action "Application des changements" \
                    "Recharge rsyslog et redémarre Promtail pour appliquer\nles nouvelles configurations de sources."
                sources_apply
                ;;
            24)
                # Guide configuration
                confirm_action "Guide de configuration" \
                    "Affiche des instructions détaillées pour configurer\nles équipements distants (firewalls, serveurs...)."
                sources_help
                ;;
            25)
                # Afficher credentials masqués
                confirm_action "Affichage des credentials" \
                    "Affiche les identifiants de connexion (mots de passe masqués)."
                creds_show
                ;;
            26)
                # Révéler credentials
                confirm_action "Révéler les credentials" \
                    "⚠️  Affiche les mots de passe en clair à l'écran.\nNe le faites que dans un environnement sécurisé !"
                creds_reveal
                ;;
            27)
                # Regénérer tous les mdp
                confirm_action "Régénération complète" \
                    "Génère de nouveaux mots de passe sécurisés pour TOUS les services.\nLes services seront réinitialisés (perte des données actuelles)."
                creds_regenerate_all
                ;;
            28)
                # Changer mdp spécifique
                confirm_action "Changement de mot de passe" \
                    "Change le mot de passe d'un service spécifique (Grafana ou InfluxDB)."
                creds_change_service
                ;;
            29)
                # Exporter credentials
                confirm_action "Export des credentials" \
                    "Exporte les credentials dans un fichier texte sécurisé."
                creds_export
                ;;
            0)
                echo
                echo -e "${CYAN}${BOLD}╔════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}${BOLD}║  Merci d'avoir utilisé HERMES ${SHIELD}     ║${NC}"
                echo -e "${CYAN}${BOLD}╚════════════════════════════════════════╝${NC}"
                echo
                echo -e "${DIM}Restez vigilant sur vos infrastructures !${NC}"
                echo
                exit 0
                ;;
            *)
                error "Choix invalide. Veuillez entrer un nombre entre 0 et 29."
                sleep 2
                ;;
        esac
        
        echo
        read -p "$(echo -e ${GRAY}Appuyez sur Entrée pour revenir au menu...${NC})" _
    done
}

# Lancer le menu principal
main_loop
