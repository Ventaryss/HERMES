<div align="center">

# 🛡️ HERMES

### **H**ighly **E**fficient **R**eal-time **M**onitoring and **E**vent **S**ystem

*Système de Monitoring en Temps Réel et d'Événements Hautement Efficace*

---

[\![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)]()
[\![Docker](https://img.shields.io/badge/docker-ready-success.svg)]()
[\![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[\![Status](https://img.shields.io/badge/status-production--ready-brightgreen.svg)]()

**Solution professionnelle de monitoring** pour vos infrastructures IT  
Centralisation • Temps réel • Multi-sources • Haute disponibilité

</div>

---

## 📋 Sommaire

- [🎯 Présentation](#-présentation)
- [✨ Fonctionnalités](#-fonctionnalités)
- [🏗️ Architecture](#️-architecture)
- [⚙️ Prérequis](#️-prérequis)
- [🚀 Installation](#-installation)
- [🔧 Configuration](#-configuration)
- [📊 Services](#-services)
- [💻 Installation client](#-installation-client)
- [🔥 Firewalls](#-firewalls)
- [🛠️ Maintenance](#️-maintenance)
- [�� Dépannage](#-dépannage)
- [💬 Support](#-support)

---

## 🎯 Présentation

**HERMES** est une stack de monitoring complète qui centralise logs et métriques de vos infrastructures IT. Inspiré du messager des dieux, HERMES transmet efficacement toutes les informations critiques vers une plateforme centralisée.

### Cas d'usage

| Type | Description |
|------|-------------|
| 🖥️ **Infrastructure** | Surveillance serveurs, conteneurs, VM |
| 📝 **Logs** | Agrégation depuis applications, systèmes |
| 🛡️ **Sécurité** | Collecte logs firewalls (pfSense, Palo Alto, Stormshield) |
| 🔔 **Alerting** | Notifications automatiques sur incidents |
| �� **Forensique** | Recherche et corrélation d'événements |

### Pourquoi HERMES ?

✅ Installation en une commande  
✅ Configuration automatique  
✅ Sécurité renforcée  
✅ Temps réel et performant  
✅ Extensible et personnalisable

---

## ✨ Fonctionnalités

### Monitoring et Métriques
- 📊 **Prometheus** - Collecte métriques temps-réel
- 📈 **Node Exporter** - Métriques système
- 🔔 **Alerting** - Règles configurables
- ⏱️ **Rétention** - 15 jours (modifiable)

### Logs et Agrégation
- 📝 **Loki** - Agrégation haute performance
- 🚀 **Promtail** - Collecteur intelligent  
- 🔄 **Fluentd** - Traitement avancé
- 📨 **Rsyslog** - Réception syslog multi-ports

### Visualisation
- 🎨 **Grafana** - Dashboards interactifs
- 📍 **Datasources** - Prometheus, Loki, InfluxDB  
- 🔧 **Provisioning** - Configuration as Code
- 📊 **Dashboards prêts** - Système, Logs, Firewalls

### Infrastructure
- 🐳 **Docker Compose** - Orchestration simplifiée
- �� **Réseau unifié** - Communication optimisée
- 🏥 **Healthchecks** - Surveillance état
- 💾 **Volumes persistants** - Aucune perte de données
- 🔄 **Auto-restart** - Haute disponibilité

---

## 🏗️ Architecture

```
hermes/
├── 📄 docker-compose.yml       # Orchestration complète
├── 📄 .env.example             # Template configuration
├── 📄 install.sh               # Script d'installation
│
├── 📁 config/                  # Configurations services
│   ├── grafana/
│   ├── loki/
│   ├── prometheus/
│   ├── promtail/
│   ├── fluentd/
│   └── influxdb/
│
├── 📁 scripts/                 # Scripts de configuration
├── 📁 dashboards/              # Dashboards Grafana
├── 📁 client/                  # Outils client
└── 📁 archives/                # Archives logs
```

### Flux de données

```
[Firewalls] [Clients] [Serveurs] [Apps]
     │         │          │        │
     └─────────┴──────────┴────────┘
              │
       [Rsyslog/Promtail/Fluentd]
              │
       ┌──────┴──────┐
       │             │
    [Loki]    [Prometheus]
       │             │
       └──────┬──────┘
              │
         [Grafana]
              │
        [Dashboard]
```

---

## ⚙️ Prérequis

### Configuration système

| Ressource | Minimum | Recommandé |
|-----------|---------|------------|
| **CPU** | 2 cores | 4 cores |
| **RAM** | 4 GB | 8 GB |
| **Disque** | 20 GB | 50 GB |

### Systèmes supportés

✅ Debian 10/11/12/13 • Ubuntu 20.04/22.04/24.04  
✅ CentOS 7/8 • RHEL 7/8/9 • Rocky/Alma Linux  
✅ Fedora 35+

### Logiciels

- Docker 20.10+ (installation auto)
- Docker Compose 2.0+ (installation auto)
- Git 2.0+

---

## 🚀 Installation

### En 3 étapes

#### 1. Cloner

```bash
git clone https://github.com/Ventaryss/hermes.git
cd HERMES
```

#### 2. Configurer

```bash
cp .env.example .env
nano .env
```

**Variables à modifier** :
```bash
GRAFANA_ADMIN_PASSWORD=VotreMotDePasse\!
INFLUXDB_INIT_PASSWORD=AutreMotDePasse\!
BASE_DIR=${HOME}/HERMES
TZ=Europe/Paris
```

#### 3. Installer

```bash
chmod +x install.sh
./install.sh
```

### Vérification

```bash
cd ~/HERMES
docker compose ps
```

Tous les services doivent afficher `Up` ou `healthy`.

### Accès

| Service | URL | Login |
|---------|-----|-------|
| 🎨 **Grafana** | http://localhost:3000 | admin / admin |
| 📊 **Prometheus** | http://localhost:9090 | - |
| 📝 **Loki** | http://localhost:3100 | - |
| 🗄️ **InfluxDB** | http://localhost:8086 | admin / adminadmin123 |

⚠️ Changez les mots de passe après connexion \!

---

## 🔧 Configuration

### Token InfluxDB

```bash
cd ~/HERMES
./scripts/get-influxdb-token.sh
```

Ajoutez le token dans :
```bash
nano config/grafana/provisioning/datasources/default.yaml
docker compose restart grafana
```

### Vérifier Rsyslog

```bash
sudo ss -tulpn | grep rsyslog
```

Ports attendus : 514, 5141, 5142

### Recharger configurations

```bash
# Prometheus (sans redémarrage)
curl -X POST http://localhost:9090/-/reload

# Autres services
docker compose restart [service]
```

---

## 📊 Services

| Service | Port | Rôle |
|---------|------|------|
| 🎨 Grafana | 3000 | Visualisation |
| 📊 Prometheus | 9090 | Métriques |
| 📝 Loki | 3100 | Logs |
| 🚀 Promtail | 9080 | Collecteur logs |
| 🗄️ InfluxDB | 8086 | Time-series |
| 🔄 Fluentd | 24224-26 | Traitement logs |
| 📡 Node Exporter | 9100 | Métriques système |

---

## 💻 Installation client

### Sur le client

```bash
scp client/install-agent.sh user@client:/tmp/
cd /tmp
chmod +x install-agent.sh
sudo SERVER_IP=192.168.1.100 ./install-agent.sh
```

### Options

1. Rsyslog (logs)
2. Node Exporter (métriques)
3. Les deux (recommandé)

### Vérification

```bash
sudo systemctl status rsyslog
sudo systemctl status node_exporter
```

### Ajouter dans Prometheus

Éditez `~/HERMES/config/prometheus/prometheus.yml` :

```yaml
scrape_configs:
  - job_name: 'clients'
    static_configs:
      - targets:
          - '192.168.1.10:9100'
          - '192.168.1.11:9100'
```

Rechargez :
```bash
curl -X POST http://localhost:9090/-/reload
```

---

## 🔥 Firewalls

### pfSense

1. **Status > System Logs > Settings**
2. Enable Remote Logging
3. Server: `HERMES_IP:514`
4. Sauvegarder

**Vérif** : `tail -f /var/log/pfsense/pfsense.log`

### Palo Alto

1. **Device > Server Profiles > Syslog**
2. Nouveau profil :
   - Server: `HERMES_IP`
   - Port: `5142`
3. Associer aux politiques

**Vérif** : `tail -f /var/log/paloalto/paloalto.log`

### Stormshield

1. **Configuration > Notifications > Syslog**
2. Activer syslog
3. Adresse: `HERMES_IP`
4. Port: `5141`

**Vérif** : `tail -f /var/log/stormshield/stormshield.log`

---

## 🛠️ Maintenance

### Commandes essentielles

```bash
# Logs en temps réel
docker compose logs -f [service]

# Redémarrer service
docker compose restart [service]

# Arrêter/Démarrer tout
docker compose down
docker compose up -d

# Ressources
docker stats
```

### Archivage

- **Fréquence** : Quotidienne
- **Rétention** : 30 jours
- **Compression** : Automatique

```bash
# Forcer rotation
sudo logrotate -f /etc/logrotate.d/hermes-logs

# Nettoyer archives >90j
~/HERMES/scripts/cleanup-old-archives.sh
```

### Sauvegardes

```bash
cd ~/HERMES
docker compose down

# Sauvegarder config
tar -czf hermes-backup-$(date +%Y%m%d).tar.gz \
    config/ dashboards/ .env

# Sauvegarder volumes
sudo tar -czf hermes-volumes-$(date +%Y%m%d).tar.gz \
    -C /var/lib/docker/volumes $(docker volume ls -q | grep hermes)

docker compose up -d
```

### Mise à jour

```bash
cd ~/HERMES
docker compose pull
docker compose up -d
```

---

## 🔍 Dépannage

### Service ne démarre pas

```bash
# Diagnostic
docker compose logs [service]
docker compose ps

# Solution
docker compose rm -f [service]
docker compose up -d [service]
```

### Loki n'ingère pas

```bash
# Vérifier Promtail
docker compose logs promtail | grep error
curl http://localhost:9080/ready

# Tester
logger -t test "Test HERMES"

# Redémarrer
docker compose restart promtail loki
```

### Prometheus ne scrape pas

```bash
# Vérifier targets
curl http://localhost:9090/api/v1/targets

# Valider config
docker exec hermes-prometheus promtool check config \
    /etc/prometheus/prometheus.yml

# Recharger
curl -X POST http://localhost:9090/-/reload
```

### Grafana datasources

```bash
# Vérifier connexion
docker exec hermes-grafana ping loki
docker exec hermes-grafana ping prometheus

# Vérifier token InfluxDB
~/HERMES/scripts/get-influxdb-token.sh

# Redémarrer
docker compose restart grafana
```

### Erreurs courantes

**Permission denied** :
```bash
sudo chown -R $(id -u):$(id -g) ~/HERMES
```

**Port occupé** :
```bash
sudo lsof -i :3000
sudo systemctl stop [service-conflit]
```

**Disque plein** :
```bash
docker system prune -a --volumes
sudo journalctl --vacuum-time=7d
~/HERMES/scripts/cleanup-old-archives.sh
```

---

## 💬 Support

### Ressources

- 📖 **Documentation** : Ce README
- 🐛 **Issues** : [GitHub Issues](https://github.com/Ventaryss/hermes/issues)
- 💬 **Discussions** : [GitHub Discussions](https://github.com/Ventaryss/hermes/discussions)
- 📧 **Email** : support@hermes-monitoring.io

### Contribution

Les contributions sont bienvenues \!

1. Fork le repository
2. Créez une branche (`git checkout -b feature/ma-feature`)
3. Committez (`git commit -m 'Ajout ma feature'`)
4. Push (`git push origin feature/ma-feature`)
5. Ouvrez une Pull Request

### Guidelines

- Suivre les conventions de code
- Documenter les nouvelles fonctionnalités
- Tester avant de soumettre
- Mettre à jour le README si nécessaire

---

## 📄 Licence

Ce projet est sous licence MIT. Voir [LICENSE](LICENSE) pour plus de détails.

---

<div align="center">

**HERMES** - Highly Efficient Real-time Monitoring and Event System

*Fait avec ❤️ pour la communauté DevOps*

[⬆ Retour en haut](#️-hermes)

</div>
