#!/bin/bash

# Activer le mode strict pour bash
set -euo pipefail

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction pour vérifier l'exécution des commandes
check_command() {
    if [[ $? -ne 0 ]]; then
        log "Erreur : $1 a échoué." >&2
        exit 1
    fi
}

# Définir le répertoire de base
BASE_DIR="${HOME}/lpi-monitoring"

# Vérifier si logrotate est installé, sinon l'installer
if ! command -v logrotate &> /dev/null; then
    log "Logrotate non trouvé. Installation..."
    sudo apt-get update
    sudo apt-get install -y logrotate
    check_command "Installation de Logrotate"
else
    log "Logrotate est déjà installé."
fi

# Créer le répertoire des logs si non existant
mkdir -p "${BASE_DIR}/loki-logs"
check_command "Création du répertoire loki-logs"

# Créer un script pour archiver les logs de la semaine précédente
ARCHIVE_SCRIPT="/usr/local/bin/archive_logs.sh"
sudo tee "$ARCHIVE_SCRIPT" > /dev/null <<EOL
#!/bin/bash
set -euo pipefail

# Définir la période de la semaine précédente
start_date=\$(date -d "last monday -1 week" +%Y-%m-%d)
end_date=\$(date -d "last monday" +%Y-%m-%d)

# Créer un dossier pour les logs de la semaine précédente
log_dir="${BASE_DIR}/loki-logs/\$start_date-to-\$end_date"
mkdir -p "\$log_dir"

# Copier les logs de la semaine précédente dans le dossier
find /var/log -type f -newermt "\$start_date" ! -newermt "\$end_date" -exec cp {} "\$log_dir" \;

# Archiver les logs
tar -czf "\$log_dir.tar.gz" -C "${BASE_DIR}/loki-logs" "\$start_date-to-\$end_date"

# Supprimer les logs non archivés
rm -r "\$log_dir"
EOL
check_command "Création du script archive_logs.sh"

# Rendre le script exécutable
sudo chmod 700 "$ARCHIVE_SCRIPT"
check_command "Mise en place des permissions du script archive_logs.sh"

# Configurer Logrotate pour archiver les logs tous les dimanches à 23h
LOGROTATE_CONF="/etc/logrotate.d/loki_logs"
ARCHIVE_DIR="/path/to/Archives_Logs/loki_logs_archives/"

# S'assurer que le répertoire d'archives existe
sudo mkdir -p "$ARCHIVE_DIR"
sudo chown loki:loki "$ARCHIVE_DIR"
sudo chmod 750 "$ARCHIVE_DIR"

sudo tee "$LOGROTATE_CONF" > /dev/null <<EOL
/var/log/loki/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    dateext
    dateformat _%Y%m%d
    olddir ${ARCHIVE_DIR}
    create 640 loki loki
    notifempty
    sharedscripts
    postrotate
        $ARCHIVE_SCRIPT
    endscript
}
EOL
check_command "Configuration de Logrotate pour Loki"

# Ajouter un cron job pour vérifier Logrotate chaque semaine
(crontab -l 2>/dev/null || true; echo "0 23 * * 0 /usr/sbin/logrotate /etc/logrotate.conf") | crontab -
check_command "Ajout de la tâche cron pour logrotate"

log "Configuration de l'archivage des logs terminée avec succès."
