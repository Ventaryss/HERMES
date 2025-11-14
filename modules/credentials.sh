#!/bin/bash
# Module credentials - Gestion sécurisée des mots de passe HERMES v3

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
ENV_FILE="${HERMES_BASE_DIR}/.env"
CREDS_FILE="${HERMES_BASE_DIR}/.credentials_backup"

# Générer un mot de passe sécurisé
generate_secure_password() {
    local length="${1:-32}"
    
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 "$length" | tr -d '\n' | head -c "$length"
    else
        # Fallback avec /dev/urandom
        tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c "$length"
    fi
}

# Afficher les credentials actuels (masqués)
creds_show() {
    section_title "Credentials actuels"
    
    if [[ ! -f "$ENV_FILE" ]]; then
        error "Fichier .env introuvable"
        return 1
    fi
    
    echo -e "${CYAN}${BOLD}📋 Services configurés :${NC}"
    echo
    
    # Grafana
    local grafana_user=$(grep "^GRAFANA_ADMIN_USER=" "$ENV_FILE" | cut -d'=' -f2)
    local grafana_pass=$(grep "^GRAFANA_ADMIN_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local grafana_masked=$(echo "$grafana_pass" | sed 's/./*/g')
    
    echo -e "${BOLD}🎨 Grafana${NC}"
    echo -e "   User     : ${GREEN}${grafana_user}${NC}"
    echo -e "   Password : ${DIM}${grafana_masked}${NC}"
    echo -e "   URL      : ${CYAN}http://localhost:3000${NC}"
    echo
    
    # InfluxDB
    local influx_user=$(grep "^INFLUXDB_INIT_USERNAME=" "$ENV_FILE" | cut -d'=' -f2)
    local influx_pass=$(grep "^INFLUXDB_INIT_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local influx_token=$(grep "^INFLUXDB_INIT_ADMIN_TOKEN=" "$ENV_FILE" | cut -d'=' -f2)
    local influx_pass_masked=$(echo "$influx_pass" | sed 's/./*/g')
    local influx_token_masked=$(echo "$influx_token" | sed 's/./*/g')
    
    echo -e "${BOLD}🗄️  InfluxDB${NC}"
    echo -e "   User     : ${GREEN}${influx_user}${NC}"
    echo -e "   Password : ${DIM}${influx_pass_masked}${NC}"
    echo -e "   Token    : ${DIM}${influx_token_masked}${NC}"
    echo -e "   URL      : ${CYAN}http://localhost:8086${NC}"
    echo
    
    # Wazuh
    local wazuh_dash_user=$(grep "^WAZUH_DASHBOARD_USER=" "$ENV_FILE" | cut -d'=' -f2)
    local wazuh_dash_pass=$(grep "^WAZUH_DASHBOARD_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local wazuh_api_user=$(grep "^WAZUH_API_USER=" "$ENV_FILE" | cut -d'=' -f2)
    local wazuh_api_pass=$(grep "^WAZUH_API_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local wazuh_dash_masked=$(echo "$wazuh_dash_pass" | sed 's/./*/g')
    local wazuh_api_masked=$(echo "$wazuh_api_pass" | sed 's/./*/g')
    
    echo -e "${BOLD}🛡️  Wazuh${NC}"
    echo -e "   Dashboard User : ${GREEN}${wazuh_dash_user}${NC}"
    echo -e "   Dashboard Pass : ${DIM}${wazuh_dash_masked}${NC}"
    echo -e "   API User       : ${GREEN}${wazuh_api_user}${NC}"
    echo -e "   API Pass       : ${DIM}${wazuh_api_masked}${NC}"
    echo -e "   URL            : ${CYAN}http://localhost:5601${NC}"
    echo
    
    echo -e "${YELLOW}${BOLD}⚠️  Sécurité :${NC}"
    echo -e "   ${DIM}• Ne partagez JAMAIS ces credentials${NC}"
    echo -e "   ${DIM}• Utilisez l'option 26 pour les révéler${NC}"
    echo -e "   ${DIM}• Utilisez l'option 27 pour les regénérer${NC}"
}

# Révéler les credentials (avec confirmation)
creds_reveal() {
    section_title "Révéler les credentials"
    
    warning "Cette action affichera les mots de passe en clair !"
    echo
    read -r -p "Êtes-vous sûr ? (tapez 'yes' pour confirmer) : " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        warning "Annulé"
        return 0
    fi
    
    clear
    echo -e "${RED}${BOLD}⚠️  CREDENTIALS EN CLAIR - NE PAS PARTAGER CET ÉCRAN ⚠️${NC}"
    echo
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    # Grafana
    local grafana_user=$(grep "^GRAFANA_ADMIN_USER=" "$ENV_FILE" | cut -d'=' -f2)
    local grafana_pass=$(grep "^GRAFANA_ADMIN_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    
    echo -e "${BOLD}🎨 GRAFANA${NC}"
    echo -e "   URL      : ${CYAN}http://localhost:3000${NC}"
    echo -e "   User     : ${GREEN}${grafana_user}${NC}"
    echo -e "   Password : ${GREEN}${grafana_pass}${NC}"
    echo
    
    # InfluxDB
    local influx_user=$(grep "^INFLUXDB_INIT_USERNAME=" "$ENV_FILE" | cut -d'=' -f2)
    local influx_pass=$(grep "^INFLUXDB_INIT_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local influx_token=$(grep "^INFLUXDB_INIT_ADMIN_TOKEN=" "$ENV_FILE" | cut -d'=' -f2)
    local influx_org=$(grep "^INFLUXDB_INIT_ORG=" "$ENV_FILE" | cut -d'=' -f2)
    local influx_bucket=$(grep "^INFLUXDB_INIT_BUCKET=" "$ENV_FILE" | cut -d'=' -f2)
    
    echo -e "${BOLD}🗄️  INFLUXDB${NC}"
    echo -e "   URL          : ${CYAN}http://localhost:8086${NC}"
    echo -e "   User         : ${GREEN}${influx_user}${NC}"
    echo -e "   Password     : ${GREEN}${influx_pass}${NC}"
    echo -e "   Token        : ${GREEN}${influx_token}${NC}"
    echo -e "   Organisation : ${GREEN}${influx_org}${NC}"
    echo -e "   Bucket       : ${GREEN}${influx_bucket}${NC}"
    echo
    
    # Wazuh
    local wazuh_dash_user=$(grep "^WAZUH_DASHBOARD_USER=" "$ENV_FILE" | cut -d'=' -f2)
    local wazuh_dash_pass=$(grep "^WAZUH_DASHBOARD_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local wazuh_api_user=$(grep "^WAZUH_API_USER=" "$ENV_FILE" | cut -d'=' -f2)
    local wazuh_api_pass=$(grep "^WAZUH_API_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local wazuh_indexer_pass=$(grep "^WAZUH_INDEXER_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    
    echo -e "${BOLD}🛡️  WAZUH${NC}"
    echo -e "   Dashboard URL  : ${CYAN}http://localhost:5601${NC}"
    echo -e "   Dashboard User : ${GREEN}${wazuh_dash_user}${NC}"
    echo -e "   Dashboard Pass : ${GREEN}${wazuh_dash_pass}${NC}"
    echo -e "   API User       : ${GREEN}${wazuh_api_user}${NC}"
    echo -e "   API Pass       : ${GREEN}${wazuh_api_pass}${NC}"
    echo -e "   Indexer Pass   : ${GREEN}${wazuh_indexer_pass}${NC}"
    echo
    
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${DIM}💾 Ces credentials sont également sauvegardés dans: ${WHITE}${CREDS_FILE}${NC}"
}

# Regénérer tous les mots de passe
creds_regenerate_all() {
    section_title "Régénération complète des credentials"
    
    warning "Cette action va regénérer TOUS les mots de passe !"
    warning "Les services devront être redémarrés et reconfigurés."
    echo
    read -r -p "Êtes-vous sûr ? (tapez 'yes' pour confirmer) : " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        warning "Annulé"
        return 0
    fi
    
    info "Génération de nouveaux mots de passe sécurisés..."
    echo
    
    # Générer les nouveaux mots de passe
    local new_grafana_pass=$(generate_secure_password 24)
    local new_influx_pass=$(generate_secure_password 24)
    local new_influx_token=$(generate_secure_password 48)
    local new_wazuh_indexer=$(generate_secure_password 24)
    local new_wazuh_api=$(generate_secure_password 24)
    local new_wazuh_dash=$(generate_secure_password 24)
    
    # Backup de l'ancien .env
    cp "$ENV_FILE" "${ENV_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    
    # Mettre à jour le .env
    sed -i "s|^GRAFANA_ADMIN_PASSWORD=.*|GRAFANA_ADMIN_PASSWORD=${new_grafana_pass}|" "$ENV_FILE"
    sed -i "s|^INFLUXDB_INIT_PASSWORD=.*|INFLUXDB_INIT_PASSWORD=${new_influx_pass}|" "$ENV_FILE"
    sed -i "s|^INFLUXDB_INIT_ADMIN_TOKEN=.*|INFLUXDB_INIT_ADMIN_TOKEN=${new_influx_token}|" "$ENV_FILE"
    sed -i "s|^WAZUH_INDEXER_PASSWORD=.*|WAZUH_INDEXER_PASSWORD=${new_wazuh_indexer}|" "$ENV_FILE"
    sed -i "s|^WAZUH_API_PASSWORD=.*|WAZUH_API_PASSWORD=${new_wazuh_api}|" "$ENV_FILE"
    sed -i "s|^WAZUH_DASHBOARD_PASSWORD=.*|WAZUH_DASHBOARD_PASSWORD=${new_wazuh_dash}|" "$ENV_FILE"
    
    # Sauvegarder dans un fichier sécurisé
    cat > "$CREDS_FILE" <<EOF
# ═══════════════════════════════════════════════════════════
# HERMES - CREDENTIALS BACKUP
# Généré le: $(date)
# ═══════════════════════════════════════════════════════════
# ⚠️  CONFIDENTIEL - NE PAS PARTAGER CE FICHIER !
# ═══════════════════════════════════════════════════════════

# GRAFANA
GRAFANA_USER=admin
GRAFANA_PASSWORD=${new_grafana_pass}
GRAFANA_URL=http://localhost:3000

# INFLUXDB
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=${new_influx_pass}
INFLUXDB_TOKEN=${new_influx_token}
INFLUXDB_URL=http://localhost:8086
INFLUXDB_ORG=hermes
INFLUXDB_BUCKET=logs

# WAZUH
WAZUH_DASHBOARD_USER=admin
WAZUH_DASHBOARD_PASSWORD=${new_wazuh_dash}
WAZUH_DASHBOARD_URL=http://localhost:5601
WAZUH_API_USER=wazuh-api
WAZUH_API_PASSWORD=${new_wazuh_api}
WAZUH_INDEXER_PASSWORD=${new_wazuh_indexer}
WAZUH_API_URL=https://localhost:55000

# PROMETHEUS
PROMETHEUS_URL=http://localhost:9090

# LOKI
LOKI_URL=http://localhost:3100
EOF
    
    chmod 600 "$CREDS_FILE"
    
    success "Nouveaux mots de passe générés avec succès !"
    echo
    info "Les credentials ont été sauvegardés dans: ${WHITE}${CREDS_FILE}${NC}"
    echo
    warning "⚠️  IMPORTANT : Vous devez maintenant :"
    echo -e "   ${WHITE}1.${NC} Noter vos nouveaux credentials (option 26)"
    echo -e "   ${WHITE}2.${NC} Arrêter complètement la stack"
    echo -e "   ${WHITE}3.${NC} Supprimer les volumes Docker existants"
    echo -e "   ${WHITE}4.${NC} Redémarrer la stack (les services se réinitialiseront)"
    echo
    read -r -p "Voulez-vous que je fasse tout ça maintenant ? (yes/no) : " auto_apply
    
    if [[ "$auto_apply" == "yes" ]]; then
        _creds_apply_new_passwords
    fi
}

# Appliquer les nouveaux mots de passe
_creds_apply_new_passwords() {
    info "Arrêt de la stack..."
    (cd "$HERMES_BASE_DIR" && sudo docker compose down) || true
    
    echo
    info "Suppression des volumes pour réinitialisation..."
    sudo docker volume rm hermes_grafana-storage 2>/dev/null || true
    sudo docker volume rm hermes_influxdb-storage 2>/dev/null || true
    sudo docker volume rm hermes_wazuh-indexer-data 2>/dev/null || true
    sudo docker volume rm hermes_wazuh-manager-data 2>/dev/null || true
    
    echo
    info "Redémarrage de la stack avec les nouveaux credentials..."
    (cd "$HERMES_BASE_DIR" && sudo docker compose up -d) || true
    
    echo
    success "Stack redémarrée avec les nouveaux credentials !"
    info "Attendez 30 secondes que les services démarrent..."
}

# Changer le mot de passe d'un service spécifique
creds_change_service() {
    section_title "Changer le mot de passe d'un service"
    
    echo -e "${CYAN}Services disponibles :${NC}"
    echo -e "  ${WHITE}1${NC} - Grafana"
    echo -e "  ${WHITE}2${NC} - InfluxDB"
    echo
    
    read -r -p "Choisir un service [1-2] : " service_choice
    echo
    
    case "$service_choice" in
        1)
            _creds_change_grafana
            ;;
        2)
            _creds_change_influxdb
            ;;
        *)
            error "Choix invalide"
            return 1
            ;;
    esac
}

# Changer le mot de passe Grafana
_creds_change_grafana() {
    echo -e "${CYAN}${BOLD}═══ Changement mot de passe Grafana ═══${NC}"
    echo
    
    echo -e "${YELLOW}Options :${NC}"
    echo -e "  ${WHITE}1${NC} - Générer automatiquement (sécurisé)"
    echo -e "  ${WHITE}2${NC} - Entrer manuellement"
    echo
    
    read -r -p "Choix [1-2] : " pass_choice
    echo
    
    local new_pass
    
    if [[ "$pass_choice" == "1" ]]; then
        new_pass=$(generate_secure_password 24)
        info "Mot de passe généré automatiquement"
    else
        read -s -r -p "Nouveau mot de passe (min 12 caractères) : " new_pass
        echo
        
        if [[ ${#new_pass} -lt 12 ]]; then
            error "Mot de passe trop court (minimum 12 caractères)"
            return 1
        fi
        
        read -s -r -p "Confirmer le mot de passe : " new_pass_confirm
        echo
        
        if [[ "$new_pass" != "$new_pass_confirm" ]]; then
            error "Les mots de passe ne correspondent pas"
            return 1
        fi
    fi
    
    # Backup et mise à jour
    cp "$ENV_FILE" "${ENV_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    sed -i "s|^GRAFANA_ADMIN_PASSWORD=.*|GRAFANA_ADMIN_PASSWORD=${new_pass}|" "$ENV_FILE"
    
    # Mise à jour du fichier credentials
    _update_creds_backup "GRAFANA_PASSWORD" "$new_pass"
    
    success "Mot de passe Grafana mis à jour !"
    echo
    echo -e "${BOLD}Nouveau mot de passe :${NC} ${GREEN}${new_pass}${NC}"
    echo
    warning "⚠️  Pour appliquer, vous devez recréer le conteneur Grafana :"
    echo -e "   ${WHITE}cd ${HERMES_BASE_DIR}${NC}"
    echo -e "   ${WHITE}sudo docker compose stop grafana${NC}"
    echo -e "   ${WHITE}sudo docker volume rm hermes_grafana-storage${NC}"
    echo -e "   ${WHITE}sudo docker compose up -d grafana${NC}"
}

# Changer le mot de passe InfluxDB
_creds_change_influxdb() {
    echo -e "${CYAN}${BOLD}═══ Changement mot de passe InfluxDB ═══${NC}"
    echo
    
    echo -e "${YELLOW}Options :${NC}"
    echo -e "  ${WHITE}1${NC} - Générer automatiquement (sécurisé)"
    echo -e "  ${WHITE}2${NC} - Entrer manuellement"
    echo
    
    read -r -p "Choix [1-2] : " pass_choice
    echo
    
    local new_pass
    local new_token
    
    if [[ "$pass_choice" == "1" ]]; then
        new_pass=$(generate_secure_password 24)
        new_token=$(generate_secure_password 48)
        info "Mot de passe et token générés automatiquement"
    else
        read -s -r -p "Nouveau mot de passe (min 12 caractères) : " new_pass
        echo
        
        if [[ ${#new_pass} -lt 12 ]]; then
            error "Mot de passe trop court"
            return 1
        fi
        
        info "Génération automatique du token..."
        new_token=$(generate_secure_password 48)
    fi
    
    # Backup et mise à jour
    cp "$ENV_FILE" "${ENV_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    sed -i "s|^INFLUXDB_INIT_PASSWORD=.*|INFLUXDB_INIT_PASSWORD=${new_pass}|" "$ENV_FILE"
    sed -i "s|^INFLUXDB_INIT_ADMIN_TOKEN=.*|INFLUXDB_INIT_ADMIN_TOKEN=${new_token}|" "$ENV_FILE"
    
    # Mise à jour du fichier credentials
    _update_creds_backup "INFLUXDB_PASSWORD" "$new_pass"
    _update_creds_backup "INFLUXDB_TOKEN" "$new_token"
    
    success "Credentials InfluxDB mis à jour !"
    echo
    echo -e "${BOLD}Nouveau mot de passe :${NC} ${GREEN}${new_pass}${NC}"
    echo -e "${BOLD}Nouveau token :${NC} ${GREEN}${new_token}${NC}"
    echo
    warning "⚠️  Pour appliquer, vous devez recréer le conteneur InfluxDB :"
    echo -e "   ${WHITE}cd ${HERMES_BASE_DIR}${NC}"
    echo -e "   ${WHITE}sudo docker compose stop influxdb${NC}"
    echo -e "   ${WHITE}sudo docker volume rm hermes_influxdb-storage${NC}"
    echo -e "   ${WHITE}sudo docker compose up -d influxdb${NC}"
}

# Mettre à jour le fichier de backup credentials
_update_creds_backup() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$CREDS_FILE" ]]; then
        touch "$CREDS_FILE"
        chmod 600 "$CREDS_FILE"
    fi
    
    if grep -q "^${key}=" "$CREDS_FILE"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$CREDS_FILE"
    else
        echo "${key}=${value}" >> "$CREDS_FILE"
    fi
}

# Initialiser les credentials lors de la première installation
creds_init_install() {
    info "Génération de mots de passe sécurisés..."
    
    # Générer des mots de passe forts
    local grafana_pass=$(generate_secure_password 24)
    local influx_pass=$(generate_secure_password 24)
    local influx_token=$(generate_secure_password 48)
    local wazuh_indexer=$(generate_secure_password 24)
    local wazuh_api=$(generate_secure_password 24)
    local wazuh_dash=$(generate_secure_password 24)
    
    # Mettre à jour le .env
    sed -i "s|^GRAFANA_ADMIN_PASSWORD=.*|GRAFANA_ADMIN_PASSWORD=${grafana_pass}|" "$ENV_FILE"
    sed -i "s|^INFLUXDB_INIT_PASSWORD=.*|INFLUXDB_INIT_PASSWORD=${influx_pass}|" "$ENV_FILE"
    sed -i "s|^INFLUXDB_INIT_ADMIN_TOKEN=.*|INFLUXDB_INIT_ADMIN_TOKEN=${influx_token}|" "$ENV_FILE"
    sed -i "s|^WAZUH_INDEXER_PASSWORD=.*|WAZUH_INDEXER_PASSWORD=${wazuh_indexer}|" "$ENV_FILE"
    sed -i "s|^WAZUH_API_PASSWORD=.*|WAZUH_API_PASSWORD=${wazuh_api}|" "$ENV_FILE"
    sed -i "s|^WAZUH_DASHBOARD_PASSWORD=.*|WAZUH_DASHBOARD_PASSWORD=${wazuh_dash}|" "$ENV_FILE"
    
    # Créer le fichier de backup sécurisé
    cat > "$CREDS_FILE" <<EOF
# ═══════════════════════════════════════════════════════════
# HERMES - CREDENTIALS BACKUP
# Généré le: $(date)
# ═══════════════════════════════════════════════════════════
# ⚠️  CONFIDENTIEL - NE PAS PARTAGER CE FICHIER !
# ═══════════════════════════════════════════════════════════

# GRAFANA
GRAFANA_USER=admin
GRAFANA_PASSWORD=${grafana_pass}
GRAFANA_URL=http://localhost:3000

# INFLUXDB
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=${influx_pass}
INFLUXDB_TOKEN=${influx_token}
INFLUXDB_URL=http://localhost:8086
INFLUXDB_ORG=hermes
INFLUXDB_BUCKET=logs

# WAZUH
WAZUH_DASHBOARD_USER=admin
WAZUH_DASHBOARD_PASSWORD=${wazuh_dash}
WAZUH_DASHBOARD_URL=http://localhost:5601
WAZUH_API_USER=wazuh-api
WAZUH_API_PASSWORD=${wazuh_api}
WAZUH_INDEXER_PASSWORD=${wazuh_indexer}
WAZUH_API_URL=https://localhost:55000

# PROMETHEUS
PROMETHEUS_URL=http://localhost:9090

# LOKI
LOKI_URL=http://localhost:3100
EOF
    
    chmod 600 "$CREDS_FILE"
    
    success "✅ Credentials sécurisés générés et sauvegardés"
    info "📄 Fichier : ${WHITE}${CREDS_FILE}${NC}"
}

# Exporter les credentials vers un fichier externe
creds_export() {
    section_title "Export des credentials"
    
    read -r -p "Nom du fichier d'export (sans extension) : " export_name
    export_name="${export_name:-hermes-credentials}"
    
    local export_file="${HERMES_BASE_DIR}/${export_name}-$(date +%Y%m%d-%H%M%S).txt"
    
    if [[ -f "$CREDS_FILE" ]]; then
        cp "$CREDS_FILE" "$export_file"
    else
        # Créer depuis .env si pas de backup
        cat > "$export_file" <<EOF
# HERMES Credentials Export
# Généré le: $(date)

GRAFANA_USER=$(grep "^GRAFANA_ADMIN_USER=" "$ENV_FILE" | cut -d'=' -f2)
GRAFANA_PASSWORD=$(grep "^GRAFANA_ADMIN_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
GRAFANA_URL=http://localhost:3000

INFLUXDB_USER=$(grep "^INFLUXDB_INIT_USERNAME=" "$ENV_FILE" | cut -d'=' -f2)
INFLUXDB_PASSWORD=$(grep "^INFLUXDB_INIT_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
INFLUXDB_TOKEN=$(grep "^INFLUXDB_INIT_ADMIN_TOKEN=" "$ENV_FILE" | cut -d'=' -f2)
INFLUXDB_URL=http://localhost:8086
EOF
    fi
    
    chmod 600 "$export_file"
    
    success "Credentials exportés vers : ${WHITE}${export_file}${NC}"
    echo
    warning "⚠️  Sécurisez ce fichier et supprimez-le après utilisation !"
}
