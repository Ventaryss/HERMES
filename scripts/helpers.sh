#!/bin/bash
# Helpers communs HERMES v3

set -euo pipefail

# Couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'

readonly BOLD='\033[1m'
readonly DIM='\033[2m'

readonly CHECKMARK="✓"
readonly CROSS="✗"
readonly ARROW="→"
readonly GEAR="⚙"
readonly ROCKET="🚀"
readonly SHIELD="🛡️"

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
LOG_DIR="${PROJECT_ROOT}/logs"
MAIN_LOG="${LOG_DIR}/hermes.log"

mkdir -p "$LOG_DIR"

log() {
  local level="$1"; shift
  local msg="$*"
  echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$MAIN_LOG"
}

info() {
  echo -e "${BLUE}[INFO]${NC} $*"
  log "INFO" "$*"
}

success() {
  echo -e "${GREEN}[${CHECKMARK}]${NC} ${GREEN}$*${NC}"
  log "SUCCESS" "$*"
}

warning() {
  echo -e "${YELLOW}[!]${NC} ${YELLOW}$*${NC}"
  log "WARNING" "$*"
}

error_msg() {
  echo -e "${RED}[${CROSS}]${NC} ${RED}$*${NC}" >&2
  log "ERROR" "$*"
}

section_title() {
  local title="$1"
  local width=55
  local title_len=${#title}
  local padding=$(( (width - title_len) / 2 ))
  local padding_right=$(( width - title_len - padding ))

  echo
  echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
  printf "${BOLD}${CYAN}║${NC}%*s${WHITE}${BOLD}%s${NC}%*s${BOLD}${CYAN}║${NC}\n" $padding "" "$title" $padding_right ""
  echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
  echo
}

spinner() {
  local pid="$1"
  local message="$2"
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0

  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) %10 ))
    printf "\r${CYAN}${spin:$i:1}${NC} %s" "$message"
    sleep 0.1
  done

  wait "$pid"
  local rc=$?

  if [ "$rc" -eq 0 ]; then
    printf "\r${GREEN}${CHECKMARK}${NC} %s\n" "$message"
    return 0
  else
    printf "\r${RED}${CROSS}${NC} %s (code=%s)\n" "$message" "$rc"
    return "$rc"
  fi
}

run_with_spinner() {
  local message="$1"; shift
  local log_file="${LOG_DIR}/cmd_$(date +'%Y%m%d-%H%M%S').log"

  ("$@" >"$log_file" 2>&1) &
  local pid=$!

  LAST_LOG="$log_file" spinner "$pid" "$message" || {
    echo
    warning "Dernières lignes du log :"
    tail -n 20 "$log_file" || true
    echo
    return 1
  }
  return 0
}

detect_distro() {
  if [[ ! -f /etc/os-release ]]; then
    echo "unknown"
    return 1
  fi
  . /etc/os-release
  echo "${ID:-unknown}"
}

detect_wsl() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "native"
  fi
}

detect_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
  elif docker-compose --version >/dev/null 2>&1; then
    echo "docker-compose"
  else
    echo ""
  fi
}

confirm() {
  local question="$1"
  echo
  read -r -p "$(echo -e ${YELLOW}${BOLD}$question" (yes/no): "${NC})" answer
  if [[ "$answer" != "yes" ]]; then
    warning "Opération annulée"
    return 1
  fi
  return 0
}
