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
        sudo apt-get install -y docker-ce
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Docker a été installé avec succès."
    else
        echo "Docker est déjà installé."
    fi
}

# Fonction pour vérifier si Docker Compose est installé
function check_docker_compose_installed() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose n'est pas installé. Installation de Docker Compose..."
        # Commandes pour installer Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose a été installé avec succès."
    else
        echo "Docker Compose est déjà installé."
    fi
}

# Vérifier l'installation de Docker et Docker Compose
check_docker_installed
check_docker_compose_installed

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
            ./scripts/install_influxdb.sh
            ./scripts/install_rsyslog.sh
            ./scripts/install_script_logs.sh
            ;;
        10) exit 0 ;;
        *) echo "Option invalide." ;;
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

# Créer les répertoires nécessaires
mkdir -p ~/lpi-monitoring/loki-wal ~/lpi-monitoring/loki-logs ~/lpi-monitoring/dashboards_grafana/loki ~/lpi-monitoring/dashboards_grafana/prometheus ~/lpi-monitoring/dashboards_grafana/influxDB ~/lpi-monitoring/dashboards_grafana/pfsense ~/lpi-monitoring/pfsense-logs ~/lpi-monitoring/influxdb-storage

# Définir les bonnes permissions
sudo chown -R 10001:10001 ~/lpi-monitoring/loki-wal
sudo chown -R 472:472 ~/lpi-monitoring/loki-logs
sudo chown -R 472:472 ~/lpi-monitoring/dashboards_grafana/loki
sudo chown -R 472:472 ~/lpi-monitoring/dashboards_grafana/prometheus
sudo chown -R 472:472 ~/lpi-monitoring/dashboards_grafana/influxDB
sudo chown -R 472:472 ~/lpi-monitoring/dashboards_grafana/pfsense
sudo chown -R 472:472 ~/lpi-monitoring/pfsense-logs
sudo chown -R 472:472 ~/lpi-monitoring/influxdb-storage

# Démarrer Docker Compose
cd ~/lpi-monitoring/docker
docker compose up -d

# Attendre que les services démarrent
sleep 10

# Afficher l'état des services
docker compose ps
