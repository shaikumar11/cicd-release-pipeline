#!/usr/bin/env bash
# End-to-end proof of the release flow: deploy, upgrade, bad release auto-rollback, manual rollback.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
export DEPLOY_ROOT="$(mktemp -d)"
trap '"$ROOT_DIR/scripts/service.sh" stop staging || true; rm -rf "$DEPLOY_ROOT"' EXIT
PORT="$(port_for_env staging)"
live() { curl -s "http://127.0.0.1:${PORT}/version" | python3 -c 'import sys,json;print(json.load(sys.stdin)["version"])'; }
expect() { [ "$(live)" = "$1" ] || die "expected live version $1, got $(live)"; log "OK live=$1"; }

"$ROOT_DIR/scripts/deploy.sh" staging v1.0.0;                      expect v1.0.0
"$ROOT_DIR/scripts/deploy.sh" staging v1.1.0;                      expect v1.1.0
"$ROOT_DIR/scripts/deploy.sh" staging v1.2.0 --simulate-bad-release && die "bad release should have failed"
expect v1.1.0   # auto-rolled back
"$ROOT_DIR/scripts/rollback.sh" staging;                           expect v1.0.0
log "smoke test passed"
