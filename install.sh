#!/bin/bash

# Fonction pour afficher le menu et obtenir les choix de l'utilisateur
function show_menu() {
    echo "Sélectionnez les services à installer :"
    echo "1) Docker Compose"
    echo "2) Fluentd"
    echo "3) Grafana"
    echo "4) Loki"
    echo "5) Prometheus"
    echo "6) Promtail"
    echo "7) Rsyslog"
    echo "8) Tous les services"
    echo "9) Quitter"
}

# Fonction pour installer un service
function install_service() {
    local service=$1
    case $service in
        1) ./scripts/install_docker_compose.sh ;;
        2) ./scripts/install_fluentd.sh ;;
        3) ./scripts/install_grafana.sh ;;
        4) ./scripts/install_loki.sh ;;
        5) ./scripts.install_prometheus.sh ;;
        6) ./scripts/install_promtail.sh ;;
        7) ./scripts/install_rsyslog.sh ;;
        8)
            ./scripts/install_docker_compose.sh
            ./scripts/install_fluentd.sh
            ./scripts/install_grafana.sh
            ./scripts/install_loki.sh
            ./scripts/install_prometheus.sh
            ./scripts/install_promtail.sh
            ./scripts/install_rsyslog.sh
            ;;
        9) exit 0 ;;
        *) echo "Option invalide." ;;
    esac
}

# Boucle de menu
while true; do
    show_menu
    read -p "Entrez votre choix : " choice
    install_service $choice
done

# Créer les répertoires nécessaires
mkdir -p ~/LPI/promtail ~/LPI/prometheus ~/LPI/loki ~/LPI/loki-wal ~/LPI/loki-logs ~/LPI/fluentd ~/LPI/pfsense-logs

# Mettre les permissions pour le répertoire Loki WAL
sudo chown -R 10001:10001 ~/LPI/loki-wal

# Démarrer Docker Compose
cd ~/LPI/docker
docker compose up -d

# Attendre que les services démarrent
sleep 10

# Afficher l'état des services
docker compose ps