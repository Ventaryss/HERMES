#!/bin/bash

# ===========================================
# HERMES - Configuration InfluxDB
# ===========================================
# Script pour configurer InfluxDB 2.x
# Note: InfluxDB sera initialisé automatiquement au premier démarrage via docker-compose

set -euo pipefail

# Définir le répertoire de base
BASE_DIR="${HOME}/HERMES"

# Fonction de journalisation
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFLUXDB] $1"
}

# Fonction pour vérifier l'exécution des commandes
check_command() {
    if [[ $? -ne 0 ]]; then
        log "Erreur : $1 a échoué."
        return 1
    fi
    return 0
}

# Fonction principale pour générer la configuration
generate_influxdb_config() {
    log "Configuration d'InfluxDB..."
    
    # Créer le répertoire de configuration InfluxDB
    mkdir -p "${BASE_DIR}/configs/influxdb"
    check_command "Création du répertoire de configuration InfluxDB" || return 1
    
    # Créer un fichier de configuration InfluxDB personnalisé (optionnel)
    cat <<'EOL' > "${BASE_DIR}/configs/influxdb/config.yml"
# ===========================================
# Configuration InfluxDB 2.x
# ===========================================
# Documentation: https://docs.influxdata.com/influxdb/v2.7/reference/config-options/

# Note: La plupart des configurations sont gérées via les variables d'environnement
# dans docker-compose.yml. Ce fichier est pour des configurations avancées.

# Niveaux de log: debug, info, error
log-level: info

# Désactiver les rapports de télémétrie
reporting-disabled: true

# Configuration du stockage
storage-cache-max-memory-size: 1073741824  # 1GB
storage-cache-snapshot-memory-size: 26214400  # 25MB
storage-cache-snapshot-write-cold-duration: 10m

# Limites de requêtes
query-concurrency: 10
query-queue-size: 10

# Configuration HTTP
http-bind-address: ":8086"
http-read-header-timeout: 10s
http-read-timeout: 0
http-write-timeout: 0
http-idle-timeout: 3m

# Taille maximale du body HTTP
http-max-body-size: 0

# Configuration de la rétention
storage-retention-check-interval: 30m
EOL
    check_command "Création du fichier de configuration InfluxDB" || return 1
    
    # Créer un script d'aide pour récupérer le token après l'installation
    cat <<'EOL' > "${BASE_DIR}/get_influxdb_token.sh"
#!/bin/bash

# ===========================================
# Script pour récupérer le token InfluxDB
# ===========================================
# Utilise l'API REST d'InfluxDB pour récupérer le token admin

set -euo pipefail

INFLUXDB_URL="http://localhost:8086"
USERNAME="${INFLUXDB_INIT_USERNAME:-admin}"
PASSWORD="${INFLUXDB_INIT_PASSWORD:-adminadmin123}"

echo "Récupération du token InfluxDB..."
echo "URL: $INFLUXDB_URL"
echo "User: $USERNAME"
echo ""

# Attendre qu'InfluxDB soit prêt
echo "Vérification de la disponibilité d'InfluxDB..."
for i in {1..30}; do
    if curl -s "${INFLUXDB_URL}/health" | grep -q '"status":"pass"'; then
        echo "InfluxDB est prêt!"
        break
    fi
    echo "Attente d'InfluxDB... ($i/30)"
    sleep 2
done

# Se connecter et récupérer le token
echo ""
echo "Connexion à InfluxDB..."

# Utiliser l'API de session pour s'authentifier
SESSION=$(curl -s -X POST "${INFLUXDB_URL}/api/v2/signin" \
    -u "${USERNAME}:${PASSWORD}" \
    -H "Content-Type: application/json" || echo "")

if [[ -n "$SESSION" ]]; then
    echo "Authentification réussie"
    
    # Récupérer les tokens via l'API
    TOKEN=$(curl -s -X GET "${INFLUXDB_URL}/api/v2/authorizations" \
        -u "${USERNAME}:${PASSWORD}" \
        -H "Content-Type: application/json" | \
        jq -r '.authorizations[0].token' 2>/dev/null || echo "")
    
    if [[ -n "$TOKEN" ]] && [[ "$TOKEN" != "null" ]]; then
        echo ""
        echo "================================================"
        echo "Token InfluxDB:"
        echo "$TOKEN"
        echo "================================================"
        echo ""
        echo "Sauvegarde du token dans influxdb_token.txt..."
        echo "$TOKEN" > "${HOME}/HERMES/influxdb_token.txt"
        chmod 600 "${HOME}/HERMES/influxdb_token.txt"
        echo "Token sauvegardé!"
        echo ""
        echo "Pour l'utiliser dans Grafana, copiez ce token dans:"
        echo "  ${HOME}/HERMES/configs/grafana/provisioning/datasources/default.yaml"
    else
        echo "Erreur: Impossible de récupérer le token"
        echo "Vous pouvez le récupérer manuellement via l'interface web:"
        echo "  1. Ouvrez http://localhost:8086"
        echo "  2. Connectez-vous avec: $USERNAME"
        echo "  3. Allez dans Data > API Tokens"
        exit 1
    fi
else
    echo "Erreur: Impossible de s'authentifier"
    echo "Vérifiez que les identifiants sont corrects dans le fichier .env"
    exit 1
fi
EOL
    chmod +x "${BASE_DIR}/get_influxdb_token.sh"
    check_command "Création du script de récupération du token" || return 1
    
    log "Configuration InfluxDB générée avec succès"
    log "Après le démarrage, exécutez: ${BASE_DIR}/get_influxdb_token.sh"
    return 0
}

# Exécuter la fonction si le script est appelé directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${1:-}" == "config_only" ]]; then
    generate_influxdb_config
fi
