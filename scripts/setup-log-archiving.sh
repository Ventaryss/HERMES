#!/bin/bash

# ===========================================
# HERMES - Configuration de l'archivage des logs
# ===========================================
# Configure logrotate pour archiver automatiquement les logs

set -euo pipefail

# Définir le répertoire de base
BASE_DIR="${HOME}/HERMES"
ARCHIVE_BASE="${BASE_DIR}/Archives_Logs"

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [LOG-ARCHIVE] $1"
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

# Fonction principale pour configurer l'archivage
generate_log_archiving_config() {
    log "Configuration de l'archivage des logs..."
    
    # Vérifier si logrotate est installé
    if ! command -v logrotate &> /dev/null; then
        log "Logrotate non trouvé. Installation..."
        
        local distro=$(detect_distro)
        case $distro in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y logrotate
                ;;
            centos|rhel|fedora)
                sudo yum install -y logrotate
                ;;
            *)
                log "Distribution non supportée pour l'installation automatique"
                return 1
                ;;
        esac
        
        check_command "Installation de Logrotate" || return 1
    else
        log "Logrotate est déjà installé: $(logrotate --version | head -n1)"
    fi
    
    # Créer les répertoires d'archives
    log "Création des répertoires d'archives..."
    mkdir -p "${ARCHIVE_BASE}"/{pfsense_logs,stormshield_logs,paloalto_logs,client_logs,system_logs}
    sudo chmod -R 755 "${ARCHIVE_BASE}"
    
    # Configuration logrotate pour les logs des firewalls
    sudo tee /etc/logrotate.d/hermes-logs > /dev/null <<EOL
# ===========================================
# Logrotate - HERMES
# ===========================================
# Rotation et archivage automatique des logs

# Logs pfSense
/var/log/pfsense/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    dateext
    dateformat -%Y%m%d
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        # Archiver les logs compressés dans le répertoire d'archives
        find /var/log/pfsense -name "*.gz" -mtime +1 -exec mv {} ${ARCHIVE_BASE}/pfsense_logs/ \; 2>/dev/null || true
    endscript
}

# Logs Stormshield
/var/log/stormshield/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    dateext
    dateformat -%Y%m%d
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        find /var/log/stormshield -name "*.gz" -mtime +1 -exec mv {} ${ARCHIVE_BASE}/stormshield_logs/ \; 2>/dev/null || true
    endscript
}

# Logs Palo Alto
/var/log/paloalto/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    dateext
    dateformat -%Y%m%d
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        find /var/log/paloalto -name "*.gz" -mtime +1 -exec mv {} ${ARCHIVE_BASE}/paloalto_logs/ \; 2>/dev/null || true
    endscript
}

# Logs clients
/var/log/client_logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    dateext
    dateformat -%Y%m%d
    notifempty
    create 0644 root root
    sharedscripts
    postrotate
        find /var/log/client_logs -name "*.gz" -mtime +1 -exec mv {} ${ARCHIVE_BASE}/client_logs/ \; 2>/dev/null || true
    endscript
}
EOL
    check_command "Configuration de Logrotate pour HERMES" || return 1
    
    # Créer un script de nettoyage des anciennes archives (>90 jours)
    cat <<'EOL' > "${BASE_DIR}/cleanup_old_archives.sh"
#!/bin/bash

# ===========================================
# Script de nettoyage des anciennes archives
# ===========================================
# Supprime les archives de plus de 90 jours

set -euo pipefail

ARCHIVE_BASE="${HOME}/HERMES/Archives_Logs"
RETENTION_DAYS=90

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Nettoyage des archives de plus de ${RETENTION_DAYS} jours..."

for dir in "${ARCHIVE_BASE}"/*; do
    if [[ -d "$dir" ]]; then
        echo "Vérification de: $dir"
        find "$dir" -type f -name "*.gz" -mtime +${RETENTION_DAYS} -delete
        echo "  - Archives anciennes supprimées"
    fi
done

echo "Nettoyage terminé"
EOL
    chmod +x "${BASE_DIR}/cleanup_old_archives.sh"
    check_command "Création du script de nettoyage" || return 1
    
    # Ajouter une tâche cron pour le nettoyage mensuel (optionnel)
    log "Vous pouvez ajouter une tâche cron pour le nettoyage automatique:"
    log "  0 2 1 * * ${BASE_DIR}/cleanup_old_archives.sh"
    
    # Tester la configuration logrotate
    log "Test de la configuration logrotate..."
    sudo logrotate -d /etc/logrotate.d/hermes-logs 2>&1 | head -n 20 || true
    
    log "Configuration de l'archivage terminée avec succès"
    log "Les logs seront archivés quotidiennement dans: ${ARCHIVE_BASE}"
    return 0
}

# Exécuter la fonction si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${1:-}" == "config_only" ]]; then
    generate_log_archiving_config
fi
