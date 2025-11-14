#!/bin/bash
# Module dashboards Grafana pour HERMES v3

set -euo pipefail

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
COMPOSE_CMD="${COMPOSE_CMD:-}"

dash_init_env() {
  if [[ -f "${HERMES_BASE_DIR}/.env" ]]; then
    # shellcheck disable=SC2046
    export $(grep -E '^(GRAFANA_ADMIN_USER|GRAFANA_ADMIN_PASSWORD|BASE_DIR|TZ)=' "${HERMES_BASE_DIR}/.env" | xargs -d '\n' -I {} echo {})
  fi
  GRAFANA_ADMIN_USER="${GRAFANA_ADMIN_USER:-admin}"
  GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin}"
  GRAFANA_URL="${GRAFANA_URL:-http://127.0.0.1:3000}"
}

dash_init_compose_cmd() {
  if [[ -n "${COMPOSE_CMD:-}" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "docker-compose introuvable."
    exit 1
  fi
}

dash_check_grafana_up() {
  dash_init_env
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" "${GRAFANA_URL}/api/health" || echo "000")
  if [[ "$code" != "200" ]]; then
    error_msg "Grafana ne répond pas (${code}). Assurez-vous que la stack est démarrée."
    return 1
  fi
  success "Grafana est joignable (${GRAFANA_URL})."
}

dash_reload_grafana() {
  section_title "Redémarrage de Grafana"
  dash_init_compose_cmd
  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD restart grafana) &
  spinner $! "Redémarrage Grafana"
  success "Grafana redémarré."
}

dash_list_dashboards() {
  section_title "Liste des dashboards Grafana"
  dash_check_grafana_up || return 1
  if command -v jq >/dev/null 2>&1; then
    curl -s -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" \
      "${GRAFANA_URL}/api/search?query=" \
      | jq -r '.[] | "\(.id)\t\(.uid)\t\(.title)"' \
      || error_msg "Impossible de lister les dashboards."
  else
    curl -s -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" \
      "${GRAFANA_URL}/api/search?query=" \
      || error_msg "Impossible de lister les dashboards (jq indisponible)."
  fi
}

dash_import_from_file() {
  local file_path="$1"

  section_title "Import d'un dashboard Grafana"

  if [[ ! -f "$file_path" ]]; then
    error_msg "Fichier introuvable : $file_path"
    return 1
  fi

  dash_check_grafana_up || return 1

  local json
  json="$(cat "$file_path")"

  if ! grep -q '"dashboard"' <<< "$json"; then
    warning "Le JSON ne semble pas être un export complet Grafana."
    warning "On va l'envelopper dans {'dashboard': ..., 'overwrite': true}"
    json="{\"dashboard\": ${json}, \"overwrite\": true}"
  fi

  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" \
    -H "Content-Type: application/json" \
    -X POST "${GRAFANA_URL}/api/dashboards/db" \
    --data-binary @"<(printf '%s' "$json")" || echo "000")

  if [[ "$code" == "200" || "$code" == "202" ]]; then
    success "Dashboard importé avec succès (${file_path})."
  else
    error_msg "Échec de l'import (HTTP ${code})."
    return 1
  fi
}

dash_interactive_import() {
  section_title "Ajout d'un dashboard Grafana"
  read -r -p "Chemin du fichier JSON à importer : " file_path
  dash_import_from_file "$file_path"
  dash_reload_grafana || true
}

dash_export_dashboard() {
  section_title "Export d'un dashboard Grafana"

  dash_check_grafana_up || return 1
  read -r -p "UID du dashboard à exporter : " uid
  read -r -p "Chemin de sortie (ex: dashboards/export_mon_dash.json) : " out

  mkdir -p "$(dirname "$out")"

  local code
  code=$(curl -s -o "$out" -w "%{http_code}" \
    -u "${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD}" \
    "${GRAFANA_URL}/api/dashboards/uid/${uid}" || echo "000")

  if [[ "$code" == "200" ]]; then
    success "Dashboard exporté vers ${out}."
  else
    rm -f "$out"
    error_msg "Échec de l'export (HTTP ${code})."
    return 1
  fi
}

dash_install_template() {
  section_title "Installation d'un dashboard depuis templates/"

  local tpl_dir="${HERMES_BASE_DIR}/dashboards/templates"

  if [[ ! -d "$tpl_dir" ]]; then
    error_msg "Répertoire templates introuvable : $tpl_dir"
    return 1
  fi

  echo "Templates disponibles :"
  ls -1 "$tpl_dir"/*.json 2>/dev/null || {
    warning "Aucun template JSON trouvé dans ${tpl_dir}."
    return 0
  }
  echo
  read -r -p "Nom du fichier template (sans le chemin) : " tpl_name

  local file="${tpl_dir}/${tpl_name}"
  if [[ ! -f "$file" ]]; then
    error_msg "Template introuvable : $file"
    return 1
  fi

  dash_import_from_file "$file"
  dash_reload_grafana || true
}
