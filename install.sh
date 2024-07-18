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

# Fonction pour vérifier si dos2unix est installé
function check_dos2unix_installed() {
    if ! command -v dos2unix &> /dev/null; then
        echo "dos2unix n'est pas installé. Installation de dos2unix..."
        sudo apt-get update
        sudo apt-get install -y dos2unix
        echo "dos2unix a été installé avec succès."
    else
        echo "dos2unix est déjà installé."
    fi
}

# Vérifier l'installation de Docker, Docker Compose et dos2unix
check_docker_installed
check_docker_compose_installed
check_dos2unix_installed

# Convertir tous les scripts au format Unix pour éviter les problèmes d'encodage et donner les permissions d'exécution
find . -type f -name "*.sh" -exec dos2unix {} \;
find . -type f -name "*.sh" -exec chmod +x {} \;

# Fonction pour afficher le menu et obtenir les choix de l'utilisateur
function show_menu() {
    echo "Sélectionnez les services à installer :"
    echo "1) Fluentd"
    echo "2) Grafana"
    echo "3) Loki"
    echo "4) Prometheus"
    echo "5) Promtail"
    echo "6) InfluxDB"
    echo "7) Rsyslog"
    echo "8) Script d'archivage des logs"
    echo "9) Tous les services"
    echo "10) Quitter"
}

# Fonction pour installer un service
function install_service() {
    local service=$1
    case $service in
        1) ./scripts/install_fluentd.sh ;;
        2) ./scripts/install_grafana.sh ;;
        3) ./scripts/install_loki.sh ;;
        4) ./scripts/install_prometheus.sh ;;
        5) ./scripts/install_promtail.sh ;;
        6) ./scripts/install_influxdb.sh ;;
        7) ./scripts/install_rsyslog.sh ;;
        8) ./scripts/install_script_logs.sh ;;
        9)
            ./scripts/install_fluentd.sh
            ./scripts/install_grafana.sh
            ./scripts/install_loki.sh
            ./scripts/install_prometheus.sh
            ./scripts/install_promtail.sh
            ./scripts.install_influxdb.sh
            ./scripts/install_rsyslog.sh
            ./scripts/install_script_logs.sh
            ;;
        10) return 1 ;;
        *) echo "Option invalide." ;;
    esac
    return 0
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
mkdir -p ~/lpi-monitoring/loki-wal ~/lpi-monitoring/loki-logs ~/lpi-monitoring/dashboards_grafana/loki ~/lpi-monitoring/dashboards_grafana/prometheus ~/lpi-monitoring/dashboards_grafana/influxDB ~/lpi-monitoring/dashboards_grafana/pfsense ~/lpi-monitoring/pfsense-logs ~/lpi-monitoring/influxdb-storage

# Définir les permissions pour root
sudo chown -R root:root ~/lpi-monitoring/loki-wal ~/lpi-monitoring/loki-logs ~/lpi-monitoring/dashboards_grafana/loki ~/lpi-monitoring/dashboards_grafana/prometheus ~/lpi-monitoring/dashboards_grafana/influxDB ~/lpi-monitoring/dashboards_grafana/pfsense ~/lpi-monitoring/pfsense-logs ~/lpi-monitoring/influxdb-storage
sudo chmod -R 777 ~/lpi-monitoring/loki-wal ~/lpi-monitoring/loki-logs ~/lpi-monitoring/dashboards_grafana/loki ~/lpi-monitoring/dashboards_grafana/prometheus ~/lpi-monitoring/dashboards_grafana/influxDB ~/lpi-monitoring/dashboards_grafana/pfsense ~/lpi-monitoring/pfsense-logs ~/lpi-monitoring/influxdb-storage

# Boucle de menu
while true; do
    show_menu
    read -p "Entrez votre choix : " choice
    install_service $choice

    # Si l'utilisateur choisit de quitter, sortir de la boucle
    if [ "$choice" -eq 10 ]; then
        break
    fi
done

# Attendre que les services démarrent
sleep 10

# Afficher l'état des services
docker compose ps
