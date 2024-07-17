#!/bin/bash

# Créer le répertoire des logs si non existant
mkdir -p ~/LPI/loki-logs

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

# Rendre le script exécutable
chmod +x /usr/local/bin/archive_logs.sh

# Ajouter un cron job pour exécuter le script tous les lundis à 6h du matin
(crontab -l 2>/dev/null; echo "0 6 * * 1 /usr/local/bin/archive_logs.sh") | crontab -
