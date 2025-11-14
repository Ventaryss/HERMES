#!/bin/bash
# Module health HERMES v3

set -euo pipefail

HERMES_BASE_DIR="${HERMES_BASE_DIR:-$PROJECT_ROOT}"
COMPOSE_CMD="${COMPOSE_CMD:-}"

health_init_compose_cmd() {
  if [[ -n "${COMPOSE_CMD:-}" ]]; then
    return 0
  fi
  COMPOSE_CMD="$(detect_docker_compose)"
  if [[ -z "$COMPOSE_CMD" ]]; then
    error_msg "docker-compose introuvable."
    exit 1
  fi
}

health_check_services() {
  section_title "Healthcheck des services HERMES"
  health_init_compose_cmd

  (cd "$HERMES_BASE_DIR" && $COMPOSE_CMD ps --format 'table {{.Name}}\t{{.State}}\t{{.Status}}') || {
    error_msg "Impossible de récupérer l'état des services."
    return 1
  }

  echo
  info "Détail des healthchecks (si définis) :"
  echo

  local containers
  containers=$(cd "$HERMES_BASE_DIR" && $COMPOSE_CMD ps -q || true)

  for cid in $containers; do
    local name
    name=$(docker inspect -f '{{.Name}}' "$cid" | sed 's/^\/\(.*\)/\1/')
    local health
    health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' "$cid" 2>/dev/null || echo "n/a")
    if [[ "$health" == "healthy" ]]; then
      echo -e "${GREEN}[OK]${NC} ${WHITE}${name}${NC} - health=${GREEN}${health}${NC}"
    elif [[ "$health" == "n/a" ]]; then
      echo -e "${YELLOW}[~]${NC} ${WHITE}${name}${NC} - aucun healthcheck défini"
    else
      echo -e "${RED}[KO]${NC} ${WHITE}${name}${NC} - health=${RED}${health}${NC}"
    fi
  done
}

health_ports() {
  section_title "Vérification des ports critiques"

  local ports=("3000:Grafana" "9090:Prometheus" "3100:Loki" "8086:InfluxDB")
  for entry in "${ports[@]}"; do
    local p="${entry%%:*}"
    local label="${entry##*:}"
    if ss -lnt 2>/dev/null | grep -q ":$p "; then
      success "Port ${p} (${label}) écoute."
    else
      warning "Port ${p} (${label}) ne semble pas écouter."
    fi
  done
}
