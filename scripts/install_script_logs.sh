#!/bin/bash

# Fonction pour vérifier l'exécution des commandes
check_command() {
    if [ $? -ne 0 ]; then
        echo "Erreur : $1 a échoué." >&2
        exit 1
    fi
}

# Vérifier si logrotate est installé, sinon l'installer
if ! command -v logrotate &> /dev/null; then
    echo "Logrotate non trouvé. Installation..."
    sudo apt-get update
    sudo apt-get install -y logrotate
    check_command "Installation de Logrotate"
else
    echo "Logrotate est déjà installé."
fi

# Créer le répertoire des logs si non existant
mkdir -p ~/lpi-monitoring/loki-logs
check_command "Création du répertoire loki-logs"

# Créer un script pour archiver les logs de la semaine précédente
sudo tee /usr/local/bin/archive_logs.sh > /dev/null <<EOL
#!/bin/bash

# Définir la période de la semaine précédente
start_date=\$(date -d "last monday -1 week" +%Y-%m-%d)
end_date=\$(date -d "last monday" +%Y-%m-%d)

# Créer un dossier pour les logs de la semaine précédente
log_dir=~/LPI/loki-logs/\$start_date-to-\$end_date
mkdir -p \$log_dir

# Copier les logs de la semaine précédente dans le dossier
find /var/log -type f -newermt "\$start_date" ! -newermt "\$end_date" -exec cp {} \$log_dir \;

# Archiver les logs
tar -czf \$log_dir.tar.gz -C ~/LPI/loki-logs \$start_date-to-\$end_date

# Supprimer les logs non archivés
rm -r \$log_dir
EOL
check_command "Création du script archive_logs.sh"

# Rendre le script exécutable
chmod +x /usr/local/bin/archive_logs.sh
check_command "Mise en place des permissions du script archive_logs.sh"

# Configurer Logrotate pour archiver les logs tous les dimanches à 23h
LOGROTATE_CONF="/etc/logrotate.d/loki_logs"
sudo tee $LOGROTATE_CONF > /dev/null <<EOL
/var/log/loki/*.log {
    weekly
    missingok
    rotate 4
    compress
    delaycompress
    dateext
    dateformat _Semaine_%V
    olddir /path/to/Archives_Logs/loki_logs_archives/
    create 640 loki loki
    notifempty
    sharedscripts
    postrotate
        /usr/local/bin/archive_logs.sh
    endscript
}
EOL
check_command "Configuration de Logrotate pour Loki"

# Ajouter un cron job pour vérifier Logrotate chaque semaine
(crontab -l 2>/dev/null; echo "0 23 * * 0 /usr/sbin/logrotate /etc/logrotate.conf") | crontab -
check_command "Ajout de la tâche cron pour logrotate"
