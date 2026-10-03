#!/usr/bin/env bash
# Shared helpers: logging, paths, env-to-port mapping.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_ROOT="${DEPLOY_ROOT:-$ROOT_DIR/deployments}"
KEEP_RELEASES="${KEEP_RELEASES:-3}"

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

port_for_env() {
  case "$1" in
    staging)    echo "${STAGING_PORT:-8101}" ;;
    production) echo "${PRODUCTION_PORT:-8102}" ;;
    *) die "unknown environment '$1' (use staging or production)" ;;
  esac
}
