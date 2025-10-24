#!/bin/bash

# ===========================================
# HERMES - Configuration Rsyslog
# ===========================================
# Script pour configurer rsyslog comme collecteur de logs centralisé
# Reçoit les logs des firewalls et les transmet à Fluentd/Loki

set -euo pipefail

# Définir le répertoire de base
BASE_DIR="${HOME}/HERMES"

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [RSYSLOG] $1"
}

# Fonction pour vérifier l'exécution des commandes
check_command() {
    if [[ $? -ne 0 ]]; then
        log "Erreur : $1 a échoué."
        return 1
    fi
    return 0
}

# Fonction pour détecter la distribution Linux
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Fonction principale pour installer et configurer rsyslog
generate_rsyslog_config() {
    log "Configuration de rsyslog..."
    
    # Installer rsyslog si non installé
    if ! command -v rsyslogd &> /dev/null; then
        log "rsyslog non trouvé. Installation..."
        
        local distro=$(detect_distro)
        case $distro in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y rsyslog rsyslog-relp
                ;;
            centos|rhel|fedora)
                sudo yum install -y rsyslog rsyslog-relp
                ;;
            *)
                log "Distribution non supportée pour l'installation automatique de rsyslog"
                return 1
                ;;
        esac
        
        check_command "Installation de rsyslog" || return 1
    else
        log "rsyslog est déjà installé: $(rsyslogd -v | head -n1)"
    fi
    
    # Créer les répertoires de logs
    sudo mkdir -p /var/log/{pfsense,stormshield,paloalto,client_logs}
    sudo chmod -R 755 /var/log/{pfsense,stormshield,paloalto,client_logs}
    
    # Créer le fichier de configuration rsyslog pour HERMES
    sudo tee /etc/rsyslog.d/10-hermes.conf > /dev/null <<'EOL'
# ===========================================
# Configuration Rsyslog - HERMES
# ===========================================
# Collecteur de logs centralisé pour firewalls et clients

# === Modules nécessaires ===
module(load="imudp")  # Support UDP
module(load="imtcp")  # Support TCP
module(load="omfwd")  # Forward vers autres systèmes

# === Template JSON détaillé ===
template(name="JSONFormat" type="list") {
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
    constant(value="\",\"source_ip\":\"")
    property(name="fromhost-ip")
    constant(value="\"}\n")
}

# === Écoute UDP sur port 514 (syslog standard) ===
input(type="imudp" port="514" ruleset="remote_logs")

# === Écoute TCP sur port 514 (syslog sécurisé) ===
input(type="imtcp" port="514" ruleset="remote_logs")

# === Port dédié Stormshield (UDP 5141) ===
input(type="imudp" port="5141" ruleset="stormshield_logs")

# === Port dédié Palo Alto (UDP 5142) ===
input(type="imudp" port="5142" ruleset="paloalto_logs")

# === Ruleset pour logs distants génériques ===
ruleset(name="remote_logs") {
    # Filtrer pfSense
    if ($hostname contains "pfsense" or $msg contains "pfSense") then {
        action(type="omfile" file="/var/log/pfsense/pfsense.log")
        action(
            type="omfwd"
            target="127.0.0.1"
            port="24224"
            protocol="tcp"
            template="JSONFormat"
            queue.type="LinkedList"
            queue.size="10000"
            action.resumeRetryCount="-1"
        )
        stop
    }
    
    # Logs clients (non locaux)
    if ($fromhost-ip != "127.0.0.1") then {
        action(type="omfile" file="/var/log/client_logs/client.log" template="JSONFormat")
        stop
    }
}

# === Ruleset pour Stormshield ===
ruleset(name="stormshield_logs") {
    action(type="omfile" file="/var/log/stormshield/stormshield.log")
    action(
        type="omfwd"
        target="127.0.0.1"
        port="24225"
        protocol="tcp"
        template="JSONFormat"
        queue.type="LinkedList"
        queue.size="10000"
    )
    stop
}

# === Ruleset pour Palo Alto ===
ruleset(name="paloalto_logs") {
    action(type="omfile" file="/var/log/paloalto/paloalto.log")
    action(
        type="omfwd"
        target="127.0.0.1"
        port="24226"
        protocol="tcp"
        template="JSONFormat"
        queue.type="LinkedList"
        queue.size="10000"
    )
    stop
}

# === Configuration globale ===
$WorkDirectory /var/spool/rsyslog
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$RepeatedMsgReduction on
$FileOwner syslog
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022
$PrivDropToUser syslog
$PrivDropToGroup syslog
EOL
    check_command "Création du fichier de configuration rsyslog" || return 1
    
    # Activer et démarrer rsyslog
    sudo systemctl enable rsyslog 2>/dev/null || true
    sudo systemctl restart rsyslog
    check_command "Redémarrage de rsyslog" || return 1
    
    # Vérifier le statut
    if sudo systemctl is-active --quiet rsyslog; then
        log "rsyslog est actif et en cours d'exécution"
    else
        log "Attention: rsyslog n'est pas actif"
        return 1
    fi
    
    # Afficher les ports en écoute
    log "Ports rsyslog en écoute:"
    sudo ss -tulpn | grep rsyslog || log "Aucun port rsyslog détecté (peut nécessiter quelques secondes)"
    
    log "Configuration rsyslog terminée avec succès"
    return 0
}

# Exécuter la fonction si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${1:-}" == "config_only" ]]; then
    generate_rsyslog_config
fi
