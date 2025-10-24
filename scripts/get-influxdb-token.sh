#!/bin/bash

# ═══════════════════════════════════════════════════
# HERMES - Récupération du token InfluxDB
# ═══════════════════════════════════════════════════

set -euo pipefail

readonly CYAN='\033[0;36m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

INFLUXDB_URL="http://localhost:8086"
USERNAME="${INFLUXDB_INIT_USERNAME:-admin}"
PASSWORD="${INFLUXDB_INIT_PASSWORD:-adminadmin123}"

echo -e "${CYAN}${BOLD}"
echo "╔═══════════════════════════════════════════════╗"
echo "║     Récupération du token InfluxDB           ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}URL:${NC} ${WHITE}${INFLUXDB_URL}${NC}"
echo -e "${CYAN}User:${NC} ${WHITE}${USERNAME}${NC}"
echo

echo -e "${YELLOW}Vérification d'InfluxDB...${NC}"

for i in {1..30}; do
    if curl -s "${INFLUXDB_URL}/health" | grep -q '"status":"pass"'; then
        echo -e "${GREEN}✓ InfluxDB est prêt !${NC}"
        break
    fi
    echo -ne "\r${CYAN}Attente... ($i/30)${NC}"
    sleep 2
done

echo
echo -e "${YELLOW}Connexion à InfluxDB...${NC}"

TOKEN=$(curl -s -X GET "${INFLUXDB_URL}/api/v2/authorizations" \
    -u "${USERNAME}:${PASSWORD}" \
    -H "Content-Type: application/json" | \
    jq -r '.authorizations[0].token' 2>/dev/null || echo "")

if [[ -n "$TOKEN" ]] && [[ "$TOKEN" != "null" ]]; then
    echo
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║          Token InfluxDB récupéré !           ║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}${TOKEN}${NC}"
    echo
    
    echo "${TOKEN}" > "${HOME}/HERMES/influxdb-token.txt"
    chmod 600 "${HOME}/HERMES/influxdb-token.txt"
    
    echo -e "${GREEN}✓ Token sauvegardé dans:${NC} ${WHITE}${HOME}/HERMES/influxdb-token.txt${NC}"
    echo
    echo -e "${CYAN}Pour l'utiliser dans Grafana:${NC}"
    echo -e "  ${WHITE}nano ~/HERMES/config/grafana/provisioning/datasources/default.yaml${NC}"
    echo -e "  ${YELLOW}Remplacez YOUR_INFLUXDB_TOKEN_HERE par le token ci-dessus${NC}"
    echo -e "  ${WHITE}docker compose restart grafana${NC}"
else
    echo -e "${RED}✗ Impossible de récupérer le token${NC}"
    echo
    echo -e "${YELLOW}Récupération manuelle:${NC}"
    echo "  1. Ouvrez http://localhost:8086"
    echo "  2. Connectez-vous avec: ${USERNAME}"
    echo "  3. Allez dans Data > API Tokens"
    exit 1
fi
