#!/bin/bash

# Fonction pour installer Node Exporter
install_node_exporter() {
    if [ "$(uname)" == "Linux" ]; then
        echo "Installation de Node Exporter sur Linux"
        # Télécharger et installer Node Exporter
        curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz
        tar xvf node_exporter-1.1.2.linux-amd64.tar.gz
        sudo mv node_exporter-1.1.2.linux-amd64/node_exporter /usr/local/bin/
        rm -rf node_exporter-1.1.2.linux-amd64*
        # Créer un service systemd pour Node Exporter
        sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOL
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOL
        # Créer un utilisateur pour Node Exporter
        sudo useradd --no-create-home --shell /bin/false node_exporter
        sudo systemctl daemon-reload
        sudo systemctl start node_exporter
        sudo systemctl enable node_exporter
    elif [ "$(uname)" == "Windows_NT" ]; then
        echo "Installation de Node Exporter sur Windows"
        # Télécharger et installer Node Exporter pour Windows
        curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.windows-amd64.zip
        unzip node_exporter-1.1.2.windows-amd64.zip
        mv node_exporter-1.1.2.windows-amd64/node_exporter.exe /c/Windows/System32/
        rm -rf node_exporter-1.1.2.windows-amd64*
        # Créer un service pour Node Exporter
        sc.exe create NodeExporter binPath= "C:\Windows\System32\node_exporter.exe" start= auto
        sc.exe start NodeExporter
    fi
}

# Demander à l'utilisateur s'il veut installer Node Exporter
read -p "Voulez-vous installer Node Exporter (y/n) ? " install_node_exporter_choice

# Installer rsyslog si non installé
if ! command -v rsyslogd &> /dev/null
then
    echo "rsyslog non trouvé. Installation..."
    sudo apt-get update
    sudo apt-get install -y rsyslog rsyslog-relp
else
    echo "rsyslog est déjà installé."
fi

# Configurer rsyslog pour transférer les logs au serveur central
sudo tee /etc/rsyslog.d/forward-logs.conf > /dev/null <<EOL
template(name="t_detailed" type="list") {
    constant(value="{")
    constant(value="\"Time\":\"") property(name="timereported" dateFormat="rfc3339")
    constant(value="\",\"Host\":\"") property(name="hostname")
    constant(value="\",\"Program\":\"") property(name="programname")
    constant(value="[") property(name="procid")
    constant(value="]\",\"Source IP\":\"") property(name="source")
    constant(value="\",\"Destination IP\":\"") property(name="destination")
    constant(value="\",\"Source Port\":\"") property(name="srcport")
    constant(value="\",\"Destination Port\":\"") property(name="dstport")
    constant(value="\",\"Protocol\":\"") property(name="protocol")
    constant(value="\",\"User\":\"") property(name="username")
    constant(value="\",\"URL\":\"") property(name="url")
    constant(value="\",\"Action\":\"") property(name="action")
    constant(value="\",\"Bytes Sent\":\"") property(name="sentbytecount")
    constant(value="\",\"Bytes Received\":\"") property(name="receivedbytecount")
    constant(value="\",\"Rule\":\"") property(name="rule")
    constant(value="\",\"Reason\":\"") property(name="reason")
    constant(value="\"}\n")
}
*.* action(type="omfwd" target="SERVER_IP" port="514" protocol="udp" template="t_detailed")
EOL

# Redémarrer rsyslog pour appliquer la nouvelle configuration
sudo systemctl restart rsyslog

# Installer Node Exporter si l'utilisateur le souhaite
if [ "$install_node_exporter_choice" == "y" ]; then
    install_node_exporter
fi
