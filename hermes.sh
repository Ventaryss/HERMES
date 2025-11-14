#!/bin/bash
set -euo pipefail

###############################################################################
#                               HERMES v3.1 MENU                              
#                 (Bannière identique – Menu refondu & pro)                   
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Chargement des helpers (couleurs, spinner, system_info…)
. "${SCRIPT_DIR}/scripts/helpers.sh"

HERMES_BLUE="\033[38;5;39m"
HERMES_LIGHTBLUE="\033[38;5;45m"
HERMES_CYAN="\033[38;5;44m"
HERMES_GREEN="\033[38;5;82m"
HERMES_YELLOW="\033[38;5;190m"
HERMES_MAGENTA="\033[38;5;171m"
HERMES_GREY="\033[38;5;245m"

###############################################################################
#                          BANNIÈRE (inchangée)                                
###############################################################################

show_banner() {
clear
echo -e "${HERMES_CYAN}"
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

###############################################################################
#                               TITRES DE SECTIONS                             
###############################################################################

section_title() {
    local color="$1"
    local title="$2"

    echo -e "${color}┌───────────────────────────────────────────────────────────────┐${NC}"
    printf "${color}│ %-61s │${NC}\n" " $title"
    echo -e "${color}└───────────────────────────────────────────────────────────────┘${NC}"
}

###############################################################################
#                                 SOUS-MODULES                                 
###############################################################################

core="${SCRIPT_DIR}/modules/core.sh"
dashboards="${SCRIPT_DIR}/modules/dashboards.sh"
backup="${SCRIPT_DIR}/modules/backup.sh"
health="${SCRIPT_DIR}/modules/health.sh"
logs="${SCRIPT_DIR}/modules/logs.sh"

###############################################################################
#                          AFFICHAGE DU MENU PRINCIPAL                         
###############################################################################

show_menu() {
    show_banner

    echo
    echo -e "${HERMES_LIGHTBLUE}Plateforme de monitoring centralisé • Logs • Métriques${NC}"
    echo

    #### INSTALLATION & CONFIGURATION ########################################
    section_title "${HERMES_CYAN}" "🔧 INSTALLATION & CONFIGURATION"

    echo -e " ${HERMES_LIGHTBLUE} 1${NC}  Installation complète (Docker + dépendances + stack)"
    echo -e " ${HERMES_LIGHTBLUE} 2${NC}  Démarrer la stack HERMES"
    echo -e " ${HERMES_LIGHTBLUE} 3${NC}  Arrêter la stack HERMES"
    echo -e " ${HERMES_LIGHTBLUE} 4${NC}  Redémarrer la stack"
    echo -e " ${HERMES_LIGHTBLUE} 5${NC}  Afficher l'état des services"
    echo

    #### DASHBOARDS GRAFANA ##################################################
    section_title "${HERMES_MAGENTA}" "📊 DASHBOARDS GRAFANA"

    echo -e " ${HERMES_LIGHTBLUE} 6${NC}  Lister les dashboards"
    echo -e " ${HERMES_LIGHTBLUE} 7${NC}  Importer un dashboard (JSON local)"
    echo -e " ${HERMES_LIGHTBLUE} 8${NC}  Installer un dashboard depuis templates/"
    echo -e " ${HERMES_LIGHTBLUE} 9${NC}  Exporter un dashboard"
    echo -e " ${HERMES_LIGHTBLUE}10${NC}  Recharger Grafana"
    echo

    #### BACKUPS & LOGS ######################################################
    section_title "${HERMES_YELLOW}" "💾 BACKUPS & LOGS"

    echo -e " ${HERMES_LIGHTBLUE}11${NC}  Sauvegarde complète (config + volumes)"
    echo -e " ${HERMES_LIGHTBLUE}12${NC}  Suivre les logs d'un service"
    echo -e " ${HERMES_LIGHTBLUE}13${NC}  Exporter tous les logs Docker"
    echo

    #### HEALTHCHECK #########################################################
    section_title "${HERMES_GREEN}" "💉 HEALTHCHECK & DIAGNOSTIC"

    echo -e " ${HERMES_LIGHTBLUE}14${NC}  Vérifier la santé des services"
    echo -e " ${HERMES_LIGHTBLUE}15${NC}  Vérifier les ports critiques"
    echo

    #### AUTRES ##############################################################
    section_title "${HERMES_GREY}" "⚙️  AUTRES"

    echo -e " ${HERMES_LIGHTBLUE} 0${NC}  Quitter"
    echo

    #### FOOTER SYSTEME ######################################################
    detect_system_info

    echo -e "${HERMES_GREY}Système :${NC} ${HERMES_CYAN}${SYS_INFO}${NC}"
    echo
}

###############################################################################
#                              LOGIQUE DU MENU                                
###############################################################################

while true; do
    show_menu

    echo -ne "${HERMES_CYAN}Votre choix [0-15]: ${NC}"
    read -r choice

    case "$choice" in
        1) bash "$core" install ;;
        2) bash "$core" start ;;
        3) bash "$core" stop ;;
        4) bash "$core" restart ;;
        5) bash "$core" status ;;

        6) bash "$dashboards" list ;;
        7) bash "$dashboards" import ;;
        8) bash "$dashboards" install_template ;;
        9) bash "$dashboards" export ;;
       10) bash "$dashboards" reload ;;

       11) bash "$backup" full ;;
       12) bash "$logs" follow ;;
       13) bash "$logs" export_all ;;

       14) bash "$health" check ;;
       15) bash "$health" ports ;;

        0) echo -e "${HERMES_GREEN}À bientôt dans HERMES !${NC}"; exit 0 ;;
        *) echo -e "${HERMES_YELLOW}Choix invalide.${NC}" ;;
    esac

    echo -e "\n${HERMES_GREY}Appuyez sur Entrée pour revenir au menu...${NC}"
    read -r
done
