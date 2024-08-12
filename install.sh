#!/bin/bash

# Fonction pour vérifier si Docker est installé
function check_docker_installed() {
    if ! command -v docker &> /dev/null; then
        echo "Docker n'est pas installé. Installation de Docker..."
        # Commandes pour installer Docker sur Debian
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Docker a été installé avec succès."
    else
        echo "Docker est déjà installé."
    fi
}

# Fonction pour vérifier si Docker Compose est installé (plugin intégré à Docker)
function check_docker_compose_installed() {
    if ! docker compose version &> /dev/null; then
        echo "Docker Compose n'est pas installé. Installation de Docker Compose..."
        # Commandes pour installer Docker Compose comme plugin Docker
        sudo apt-get update
        sudo apt-get install -y docker-compose-plugin
        echo "Docker Compose a été installé avec succès."
    else
        echo "Docker Compose est déjà installé."
    fi
}

# Vérifier l'installation de Docker et Docker Compose
check_docker_installed
check_docker_compose_installed

# Vérifier l'installation de dos2unix
if ! command -v dos2unix &> /dev/null; then
    echo "dos2unix n'est pas installé. Installation de dos2unix..."
    sudo apt-get update
    sudo apt-get install -y dos2unix
    echo "dos2unix a été installé avec succès."
else
    echo "dos2unix est déjà installé."
fi

# Convertir tous les scripts au format Unix pour éviter les problèmes d'encodage et donner les permissions d'exécution
find . -type f -name "*.sh" -exec dos2unix {} \;
find . -type f -name "*.sh" -exec chmod +x {} \;

# Fonction pour afficher le menu de sélection des services
function show_menu() {
    SERVICES=$(whiptail --title "Sélection des services" --checklist \
    "Sélectionnez les services à installer :" 20 78 10 \
    "Fluentd" "Installer Fluentd" ON \
    "Grafana" "Installer Grafana" ON \
    "Loki" "Installer Loki" ON \
    "Prometheus" "Installer Prometheus" ON \
    "Promtail" "Installer Promtail" ON \
    "InfluxDB" "Installer InfluxDB" ON \
    "Rsyslog" "Installer Rsyslog" ON \
    "Archivage" "Installer le script d'archivage des logs" ON \
    3>&1 1>&2 2>&3)

    echo $SERVICES
}

# Fonction pour installer un service
function install_service() {
    local service=$1
    case $service in
        Fluentd) ./scripts/install_fluentd.sh ;;
        Grafana) ./scripts/install_grafana.sh ;;
        Loki) ./scripts/install_loki.sh ;;
        Prometheus) ./scripts/install_prometheus.sh ;;
        Promtail) ./scripts/install_promtail.sh ;;
        InfluxDB) ./scripts/install_influxdb.sh ;;
        Rsyslog) ./scripts/install_rsyslog.sh ;;
        Archivage) ./scripts/install_script_logs.sh ;;
        *) echo "Option invalide: $service" ;;
    esac
}

# Stop and remove existing Docker containers if they exist
containers=$(docker ps -a -q --filter "name=loki" --filter "name=prometheus" --filter "name=grafana" --filter "name=influxdb" --filter "name=fluentd" --filter "name=promtail")
if [ -n "$containers" ]; then
    docker stop $containers
    docker rm $containers
else
    echo "No existing containers to stop or remove."
fi

# Créer les répertoires nécessaires
mkdir -p ~/lpi-monitoring/loki-wal ~/lpi-monitoring/loki-logs \
         ~/lpi-monitoring/dashboards_grafana/loki \
         ~/lpi-monitoring/dashboards_grafana/prometheus \
         ~/lpi-monitoring/dashboards_grafana/influxDB \
         ~/lpi-monitoring/dashboards_grafana/pfsense \
         ~/lpi-monitoring/pfsense-logs ~/lpi-monitoring/influxdb-storage

# Définir les permissions pour root
sudo chown -R root:root ~/lpi-monitoring/loki-wal ~/lpi-monitoring/loki-logs \
                       ~/lpi-monitoring/dashboards_grafana/loki \
                       ~/lpi-monitoring/dashboards_grafana/prometheus \
                       ~/lpi-monitoring/dashboards_grafana/influxDB \
                       ~/lpi-monitoring/dashboards_grafana/pfsense \
                       ~/lpi-monitoring/pfsense-logs ~/lpi-monitoring/influxdb-storage

sudo chmod -R 777 ~/lpi-monitoring/loki-wal ~/lpi-monitoring/loki-logs \
                 ~/lpi-monitoring/dashboards_grafana/loki \
                 ~/lpi-monitoring/dashboards_grafana/prometheus \
                 ~/lpi-monitoring/dashboards_grafana/influxDB \
                 ~/lpi-monitoring/dashboards_grafana/pfsense \
                 ~/lpi-monitoring/pfsense-logs ~/lpi-monitoring/influxdb-storage

# Créer les répertoires de logs dans /var/log
sudo mkdir -p /var/log/pfsense /var/log/client_logs /var/log/stormshield /var/log/paloalto

# Définir les permissions pour les répertoires de logs dans /var/log
sudo chown -R root:root /var/log/pfsense /var/log/client_logs /var/log/stormshield /var/log/paloalto
sudo chmod -R 777 /var/log/pfsense /var/log/client_logs /var/log/stormshield /var/log/paloalto

# Boucle de menu
SERVICES=$(show_menu)

# Supprimer les guillemets et les espaces de la sortie de whiptail
SERVICES=$(echo $SERVICES | sed 's/"//g')

# Tri des services pour garantir l'ordre d'installation
declare -A order
order=( ["InfluxDB"]=1 ["Grafana"]=2 ["Prometheus"]=3 ["Loki"]=4 ["Promtail"]=5 ["Fluentd"]=6 ["Rsyslog"]=7 ["Archivage"]=8 )
IFS=$'\n'
SERVICES=$(echo $SERVICES | tr ' ' '\n' | sort -k1,1 -k2,2n | while read service; do
    echo "${order[$service]} $service"
done | sort -k1,1n | cut -d' ' -f2)

for service in $SERVICES; do
    install_service $service
done

# Attendre que les services démarrent
echo -n "Vérification en cours"
for ((i=0;i<10;i++)); do
    echo -n "."
    sleep 1
done
echo

# Afficher l'état des services
docker ps
