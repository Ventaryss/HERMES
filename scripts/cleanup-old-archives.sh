#!/bin/bash

# ═════════════════════════════════════════════════════
# HERMES - Nettoyage des archives anciennes
# Supprime les archives de logs de plus de 90 jours
# ═════════════════════════════════════════════════════

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

ARCHIVE_BASE="${HOME}/HERMES/archives"
RETENTION_DAYS=${1:-90}

echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    HERMES - Nettoyage des archives           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
echo
echo -e "${WHITE}Rétention:${NC} ${RETENTION_DAYS} jours"
echo -e "${WHITE}Répertoire:${NC} ${ARCHIVE_BASE}"
echo

for dir in "${ARCHIVE_BASE}"/*; do
    if [[ -d "$dir" ]]; then
        echo -e "${CYAN}Vérification:${NC} $(basename "$dir")"
        
        before=$(find "$dir" -name "*.gz" | wc -l)
        find "$dir" -type f -name "*.gz" -mtime +${RETENTION_DAYS} -delete
        after=$(find "$dir" -name "*.gz" | wc -l)
        
        deleted=$((before - after))
        if [[ $deleted -gt 0 ]]; then
            echo -e "${GREEN}  ✓ ${deleted} archive(s) supprimée(s)${NC}"
        else
            echo "  → Aucune archive à supprimer"
        fi
    fi
done

echo
echo -e "${GREEN}✓ Nettoyage terminé${NC}"
