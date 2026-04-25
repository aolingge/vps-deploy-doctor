#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"
TARGET_URL="${TARGET_URL:-http://127.0.0.1}"
SERVICE_NAME="${SERVICE_NAME:-}"
APP_PORT="${APP_PORT:-8080}"
JSON="false"

usage() {
  cat <<'USAGE'
vps-deploy-doctor - read-only VPS deployment diagnostics

Usage:
  vps-deploy-doctor.sh [options]

Options:
  --url URL           URL to check, default: http://127.0.0.1
  --service NAME      systemd service name, for example demo-api
  --port PORT         app port to check, default: 8080
  --json              print JSON lines
  -h, --help          show help

Environment:
  TARGET_URL          same as --url
  SERVICE_NAME        same as --service
  APP_PORT            same as --port
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) TARGET_URL="$2"; shift 2 ;;
    --service) SERVICE_NAME="$2"; shift 2 ;;
    --port) APP_PORT="$2"; shift 2 ;;
    --json) JSON="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    --version) echo "$VERSION"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

PASS=0
WARN=0
FAIL=0

emit() {
  local status="$1"
  local check="$2"
  local message="$3"
  case "$status" in
    PASS) PASS=$((PASS + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
  esac

  if [[ "$JSON" == "true" ]]; then
    printf '{"status":"%s","check":"%s","message":"%s"}\n' "$status" "$check" "$(printf '%s' "$message" | sed 's/"/\\"/g')"
  else
    printf '%-5s %-18s %s\n' "$status" "$check" "$message"
  fi
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

check_os() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    emit PASS os "${PRETTY_NAME:-Linux}"
  else
    emit WARN os "Cannot read /etc/os-release"
  fi
}

check_nginx() {
  if ! has_cmd nginx; then
    emit WARN nginx "nginx is not installed or not in PATH"
    return
  fi

  if nginx -t >/tmp/vps-deploy-doctor-nginx.log 2>&1; then
    emit PASS nginx "nginx -t passed"
  else
    emit FAIL nginx "nginx -t failed; run: sudo nginx -t"
  fi

  if has_cmd systemctl && systemctl is-active --quiet nginx; then
    emit PASS nginx-service "nginx is active"
  else
    emit WARN nginx-service "nginx is not active or systemctl is unavailable"
  fi
}

check_http() {
  if ! has_cmd curl; then
    emit WARN http "curl is not installed"
    return
  fi

  local code
  code="$(curl -k -L -sS -o /tmp/vps-deploy-doctor-http.txt -w '%{http_code}' "$TARGET_URL" || true)"
  if [[ "$code" =~ ^(200|204|301|302)$ ]]; then
    emit PASS http "$TARGET_URL returned HTTP $code"
  else
    emit FAIL http "$TARGET_URL returned HTTP ${code:-000}"
  fi
}

check_port() {
  if has_cmd ss; then
    if ss -ltn | awk '{print $4}' | grep -Eq "[:.]$APP_PORT$"; then
      emit PASS port "something is listening on TCP $APP_PORT"
    else
      emit WARN port "nothing is listening on TCP $APP_PORT"
    fi
  else
    emit WARN port "ss command not found"
  fi
}

check_service() {
  if [[ -z "$SERVICE_NAME" ]]; then
    emit WARN systemd "no --service provided"
    return
  fi

  if ! has_cmd systemctl; then
    emit WARN systemd "systemctl is not available"
    return
  fi

  if systemctl is-active --quiet "$SERVICE_NAME"; then
    emit PASS systemd "$SERVICE_NAME is active"
  else
    emit FAIL systemd "$SERVICE_NAME is not active"
  fi
}

check_firewall() {
  if has_cmd ufw; then
    local status
    status="$(ufw status 2>/dev/null | head -n 1 || true)"
    emit PASS firewall "ufw: ${status:-unknown}"
  elif has_cmd firewall-cmd; then
    emit PASS firewall "firewalld detected"
  else
    emit WARN firewall "no ufw or firewalld command found"
  fi
}

check_docker() {
  if ! has_cmd docker; then
    emit WARN docker "docker is not installed"
    return
  fi

  if docker info >/dev/null 2>&1; then
    emit PASS docker "docker daemon is reachable"
  else
    emit WARN docker "docker installed but daemon is not reachable"
  fi
}

check_disk_memory() {
  if has_cmd df; then
    local root_usage
    root_usage="$(df -P / | awk 'NR==2 {print $5}')"
    emit PASS disk "root filesystem usage: $root_usage"
  fi

  if has_cmd free; then
    local mem
    mem="$(free -m | awk '/Mem:/ {print $7 "MB available"}')"
    emit PASS memory "$mem"
  fi
}

check_logs_hint() {
  if [[ -n "$SERVICE_NAME" ]]; then
    emit PASS logs "journalctl -u $SERVICE_NAME -n 100 --no-pager"
  else
    emit PASS logs "tail -f /var/log/nginx/error.log"
  fi
}

check_os
check_nginx
check_http
check_port
check_service
check_firewall
check_docker
check_disk_memory
check_logs_hint

if [[ "$JSON" == "true" ]]; then
  printf '{"summary":{"pass":%d,"warn":%d,"fail":%d}}\n' "$PASS" "$WARN" "$FAIL"
else
  echo
  echo "Summary: PASS=$PASS WARN=$WARN FAIL=$FAIL"
fi

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
