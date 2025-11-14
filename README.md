<div align="center">

# 🛡️ HERMES v3

### **H**ighly **E**fficient **R**eal-time **M**onitoring and **E**vent **S**ystem

*Plateforme Unifiée de Monitoring, Logs & Sécurité*

---

[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)]()
[![Docker](https://img.shields.io/badge/docker-compose-success.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[![Status](https://img.shields.io/badge/status-production-brightgreen.svg)]()

**Solution professionnelle tout-en-un** pour le monitoring, l'agrégation de logs et la sécurité IT

</div>

---

## 📋 Table des matières

- [🎯 Présentation](#-présentation)
- [✨ Nouveautés v3](#-nouveautés-v3)
- [🏗️ Architecture](#️-architecture)
- [⚙️ Stack Technologique](#️-stack-technologique)
- [🚀 Installation](#-installation)
- [📦 Services](#-services)
- [🔐 Credentials](#-credentials)
- [📡 Sources de Logs](#-sources-de-logs)
- [🛠️ Gestion](#️-gestion)
- [🔍 Troubleshooting](#-troubleshooting)

---

## 🎯 Présentation

**HERMES v3** centralise **logs**, **métriques** et **événements de sécurité** dans une solution unifiée et clé en main.

### 🌟 Points forts

- 🚀 **Déploiement 1-click** : Installation complète automatisée
- 🔐 **Sécurité intégrée** : Génération auto de mots de passe sécurisés
- 📡 **Multi-sources** : Firewalls, serveurs, applications, Docker
- 🛡️ **SIEM intégré** : Wazuh pour détection d'intrusions
- 📊 **Visualisation** : Grafana + Wazuh Dashboard
- ⚡ **Léger** : Stack PLG (10x moins de RAM qu'ELK)

---

## ✨ Nouveautés v3

### 🎨 Script de Gestion Unifié

```bash
sudo ./gestion_HERMES.sh  # 29 options complètes
```

**Catégories** :
- ⚙️ Installation & Démarrage (1-6)
- 📊 Dashboards Grafana (7-11)
- 💾 Sauvegardes (12-14)
- 📝 Logs (15-16)
- 💉 Healthcheck (17-19)
- 📡 **Sources de Logs** (20-24) **← NOUVEAU**
- 🔐 **Gestion Credentials** (25-29) **← NOUVEAU**

### 🔐 Credentials Sécurisés

- ✅ Génération auto mots de passe forts (24-48 car.)
- ✅ Backup sécurisé `.credentials_backup` (chmod 600)
- ✅ Options régénération et récupération

### 📡 Gestion Sources

- ✅ Ajout interactif (firewalls, serveurs, apps, Docker)
- ✅ Auto-config Promtail et rsyslog
- ✅ Templates pré-config (pfSense, Palo Alto, etc.)

### 🛡️ Wazuh SIEM

- ✅ Détection intrusions (IDS/IPS)
- ✅ File Integrity Monitoring
- ✅ Conformité (PCI DSS, HIPAA)
- ✅ Analyse vulnérabilités

---

## 🏗️ Architecture

```
HERMES v3 Platform
├─ Interfaces Web
│  ├─ Grafana (3000)
│  ├─ Wazuh Dashboard (5601)
│  └─ Prometheus (9090)
├─ Data Layer
│  ├─ Loki (logs)
│  ├─ Wazuh Indexer (security)
│  ├─ InfluxDB (time-series)
│  └─ Prometheus (metrics)
└─ Collection
   ├─ Promtail (logs)
   ├─ Wazuh Agent (security)
   └─ Node Exporter (metrics)
```

---

## ⚙️ Stack Technologique

### Monitoring & Métriques

| Service | Version | Port |
|---------|---------|------|
| Prometheus | 2.48.1 | 9090 |
| Node Exporter | 1.7.0 | 9100 |
| InfluxDB | 2.7 | 8086 |

### Logs

| Service | Version | Port |
|---------|---------|------|
| Loki | 2.9.3 | 3100 |
| Promtail | 2.9.3 | 9080 |
| Grafana | 10.2.3 | 3000 |

### Sécurité

| Service | Version | Port |
|---------|---------|------|
| Wazuh Manager | 4.7.2 | 1514, 55000 |
| Wazuh Indexer | 4.7.2 | 9200 |
| Wazuh Dashboard | 4.7.2 | 5601 |

---

## 🚀 Installation

### Prérequis

```
OS: Linux (Ubuntu 20.04+, Debian 11+)
RAM: 4 GB min (8 GB recommandé)
Disque: 50 GB min
CPU: 2 cores min
Docker: 24.0+
Docker Compose: v2.20+
```

### Installation 3 commandes

```bash
# 1. Cloner
git clone https://github.com/votre-org/HERMES.git
cd HERMES

# 2. Permissions
chmod +x gestion_HERMES.sh

# 3. Installer
sudo ./gestion_HERMES.sh
# Choisir option 1
```

✅ Installation Docker  
✅ Génération mots de passe  
✅ Configuration auto  
✅ Déploiement conteneurs  
✅ Affichage credentials  

⏱️ **Durée** : 5-10 minutes

---

## 📦 Services

### Interfaces Web

```
🎨 Grafana           → http://localhost:3000
   User: admin / Pass: [auto-généré]
   
🛡️ Wazuh Dashboard   → http://localhost:5601
   User: admin / Pass: [auto-généré]
   
📊 Prometheus        → http://localhost:9090
   
🗄️ InfluxDB          → http://localhost:8086
   User: admin / Pass: [auto-généré]
```

### Vérifier

```bash
# État services
sudo docker compose ps

# Via script (option 6)
sudo ./gestion_HERMES.sh
```

---

## 🔐 Credentials

### Afficher

```bash
sudo ./gestion_HERMES.sh
# Option 25 : Masqués
# Option 26 : En clair (confirmation)
```

### Regénérer

```bash
# TOUS les mots de passe
sudo ./gestion_HERMES.sh  # Option 27

# Un service spécifique  
sudo ./gestion_HERMES.sh  # Option 28
```

### Exporter

```bash
sudo ./gestion_HERMES.sh  # Option 29
# Fichier: hermes-credentials-DATE.txt (chmod 600)
```

### Fichiers

```
.credentials_backup               # Backup auto
.env.backup-YYYYMMDD-HHMMSS      # Backup avant modif
```

---

## 📡 Sources de Logs

### Ajouter

```bash
sudo ./gestion_HERMES.sh  # Option 21
```

### Types supportés

#### 1. 🔥 Firewalls

**Templates** : pfSense, Palo Alto, Stormshield, Fortinet, Cisco

**Auto-config** :
- Règle rsyslog
- Port d'écoute
- Forward Promtail

#### 2. 🖥️ Serveurs Linux

**Config serveur distant** :
```bash
# /etc/rsyslog.conf
*.* @@<IP_HERMES>:514
sudo systemctl restart rsyslog
```

#### 3. 📱 Applications

**Formats** : JSON, Nginx, Apache, Custom regex

**Exemple** :
```bash
Nom: nginx-app
Chemin: /var/log/nginx/*.log
Format: nginx
```

#### 4. 🐳 Docker

**Auto-découverte** :
```bash
Pattern: nginx-*
Format: json
```

### Gestion

```bash
# Lister
sudo ./gestion_HERMES.sh  # Option 20

# Supprimer
sudo ./gestion_HERMES.sh  # Option 22

# Appliquer changements
sudo ./gestion_HERMES.sh  # Option 23
```

---

## 🛠️ Gestion

### Menu (29 options)

#### ⚙️ INSTALLATION
1. Installation complète
2. Installation rapide
3. Démarrer
4. Arrêter
5. Redémarrer
6. Statut

#### 📊 DASHBOARDS
7. Lister
8. Importer JSON
9. Installer template
10. Exporter
11. Redémarrer Grafana

#### 💾 SAUVEGARDES
12. Complète
13. Configuration
14. Volumes

#### 📝 LOGS
15. Suivre service
16. Exporter

#### 💉 DIAGNOSTIC
17. Santé services
18. Ports
19. Complet

#### 📡 SOURCES
20. Lister
21. Ajouter
22. Supprimer
23. Appliquer
24. Guide config

#### 🔐 CREDENTIALS
25. Afficher (masqués)
26. Révéler (clair)
27. Regénérer
28. Changer spécifique
29. Exporter

### Docker Compose

```bash
# Démarrer
sudo docker compose up -d

# Arrêter
sudo docker compose down

# Logs
sudo docker compose logs -f grafana

# Statut
sudo docker compose ps
```

### Sauvegardes

```bash
# Via script (recommandé)
sudo ./gestion_HERMES.sh  # Option 12

# Manuel config
tar -czf backup.tar.gz docker-compose.yml .env config/

# Restaurer
tar -xzf backup.tar.gz
sudo docker compose up -d
```

---

## 🔍 Troubleshooting

### Services ne démarrent pas

```bash
# Diagnostic
sudo ./gestion_HERMES.sh  # Option 19

# Logs
sudo docker compose logs grafana

# Ports
sudo ./gestion_HERMES.sh  # Option 18
```

### Permissions

```bash
# Corriger
sudo chown -R $USER:$USER config/ logs/
chmod 755 config/
chmod 600 .env .credentials_backup
```

### Connexion impossible

```bash
# Vérifier credentials
sudo ./gestion_HERMES.sh  # Option 26

# Régénérer si oublié
sudo ./gestion_HERMES.sh  # Option 27
```

### Wazuh mémoire

```bash
# Augmenter vm.max_map_count
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Redémarrer
sudo docker compose restart wazuh-indexer
```

---

## 📂 Structure

```
HERMES/
├── gestion_HERMES.sh          # Script principal
├── docker-compose.yml         # Stack
├── .env.example              # Template
├── config/                   # Configs
│   ├── grafana/
│   ├── prometheus/
│   ├── loki/
│   ├── promtail/jobs/       # Sources custom
│   ├── wazuh/
│   └── sources.json
├── modules/                  # Modules script
│   ├── core.sh
│   ├── sources.sh           # NOUVEAU
│   └── credentials.sh       # NOUVEAU
├── dashboards/              # Grafana
├── backups/                 # Sauvegardes
└── logs/                    # Logs
```

---

## 🔒 Sécurité

### Checklist

- [ ] Changer mots de passe par défaut
- [ ] Sauvegarder `.credentials_backup`
- [ ] Configurer firewall (UFW)
- [ ] Reverse proxy HTTPS
- [ ] 2FA Grafana
- [ ] Planifier backups
- [ ] Documenter architecture

### Ports à protéger

```bash
# Publics (reverse proxy)
3000, 5601

# Internes (localhost/VPN)
9090, 9200, 8086, 3100, 55000
```

---

## 📞 Support

- 📧 Email: support@hermes.local
- 🐛 Issues: GitHub Issues
- 📚 Docs: Ce README

---

## 📝 Changelog

### v3.0.0 (2025-11-14)

✨ **Nouvelles fonctionnalités**
- Script gestion unifié `gestion_HERMES.sh` (29 options)
- Gestion automatique credentials sécurisés
- Module sources de logs avec auto-configuration
- Intégration Wazuh SIEM
- Templates firewalls pré-configurés

🔧 **Améliorations**
- Architecture complètement refactorisée
- Auto-génération mots de passe forts
- Backup automatique credentials
- Support formats logs custom
- Healthchecks améliorés

🐛 **Corrections**
- Gestion permissions automatique
- Chemins absolus dans .env
- Conflits variables readonly
- Erreurs Docker volumes

---

<div align="center">

**Made with ❤️ for IT Infrastructure Monitoring**

HERMES v3 - 2025

</div>
