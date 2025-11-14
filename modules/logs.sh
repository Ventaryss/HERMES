#!/bin/bash
# Module logs / debug HERMES v3

set -euo pipefail

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
COMPOSE_CMD="${COMPOSE_CMD:-}"

logs_init_compose_cmd() {
  if [[ -n "${COMPOSE_CMD:-}" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "docker-compose introuvable."
    exit 1
  fi
}

logs_tail_service() {
  logs_init_compose_cmd
  section_title "Logs d'un service Docker"

  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD ps --services) || {
    error_msg "Impossible de lister les services."
    return 1
  }
  echo
  read -r -p "Nom du service à suivre (exact) : " svc
  echo
  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD logs -f "$svc")
}

logs_export_all() {
  logs_init_compose_cmd
  section_title "Export global des logs Docker"

  local out_dir="${HERMES_BASE_DIR}/backups/reports"
  mkdir -p "$out_dir"
  local ts
  ts="$(date +'%Y%m%d-%H%M%S')"
  local out="${out_dir}/hermes_logs_${ts}.txt"

  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD logs) >"$out" 2>&1 || true
  success "Logs exportés dans ${out}"
}
