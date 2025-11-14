#!/bin/bash
# Module backup HERMES v3

set -euo pipefail

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
BACKUP_DIR="${HERMES_BASE_DIR}/backups"
COMPOSE_CMD="${COMPOSE_CMD:-}"

backup_init_compose_cmd() {
  if [[ -n "${COMPOSE_CMD:-}" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "docker-compose introuvable."
    exit 1
  fi
}

backup_config() {
  section_title "Sauvegarde de la configuration HERMES"

  mkdir -p "${BACKUP_DIR}/db" "${BACKUP_DIR}/volumes" "${BACKUP_DIR}/reports"
  local ts
  ts="$(date +'%Y%m%d-%H%M%S')"
  local out="${BACKUP_DIR}/hermes_config_${ts}.tar.gz"

  tar -czf "$out" \
    -C "$HERMES_BASE_DIR" \
    docker-compose.yml .env config dashboards 2>/dev/null || true

  success "Config sauvegardée dans ${out}"
}

backup_volumes() {
  section_title "Sauvegarde des volumes Docker HERMES"

  mkdir -p "${BACKUP_DIR}/volumes"
  local ts
  ts="$(date +'%Y%m%d-%H%M%S')"

  local vols=("hermes-grafana-storage" "hermes-loki-storage" "hermes-loki-wal" "hermes-prometheus-storage" "hermes-influxdb-storage")

  for v in "${vols[@]}"; do
    if docker volume inspect "$v" >/dev/null 2>&1; then
      local out="${BACKUP_DIR}/vol_${v}_${ts}.tar.gz"
      info "Sauvegarde volume ${v} -> ${out}"
      docker run --rm -v "${v}:/data" -v "${BACKUP_DIR}/volumes:/backup" alpine \
        sh -c "cd /data && tar -czf /backup/$(basename "$out") ." || warning "Échec sauvegarde volume ${v}"
    else
      warning "Volume inexistant : ${v}"
    fi
  done
  success "Sauvegarde volumes terminée (voir ${BACKUP_DIR}/volumes)."
}

backup_all() {
  backup_config
  backup_volumes
}
