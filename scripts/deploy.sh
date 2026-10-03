#!/usr/bin/env bash
# Usage: deploy.sh <staging|production> <version> [--simulate-bad-release]
# Atomic symlink-based release: copy -> switch `current` -> start -> health check.
# On a failed health check the previous release is restored automatically.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ENVNAME="${1:?environment required}"
VERSION="${2:?version required}"
BAD="${3:-}"
FAIL=0; [ "$BAD" = "--simulate-bad-release" ] && FAIL=1

PORT="$(port_for_env "$ENVNAME")"
ENV_DIR="$DEPLOY_ROOT/$ENVNAME"
REL_DIR="$ENV_DIR/releases/$VERSION"
SERVICE="$ROOT_DIR/scripts/service.sh"
HEALTH="$ROOT_DIR/scripts/healthcheck.sh"

switch_current() {  # atomic: build temp link then rename over `current`
  ln -sfn "$1" "$ENV_DIR/current.tmp" && mv -Tf "$ENV_DIR/current.tmp" "$ENV_DIR/current"
}

mkdir -p "$ENV_DIR/releases"
[ -e "$REL_DIR" ] && die "release $VERSION already exists in $ENVNAME"

PREVIOUS=""
[ -L "$ENV_DIR/current" ] && PREVIOUS="$(readlink "$ENV_DIR/current")"

log "[$ENVNAME] packaging release $VERSION"
mkdir -p "$REL_DIR"
cp -r "$ROOT_DIR/app" "$ROOT_DIR/requirements.txt" "$REL_DIR/"
echo "$VERSION" >"$REL_DIR/VERSION"

log "[$ENVNAME] switching current -> $VERSION"
switch_current "$REL_DIR"

"$SERVICE" start "$ENVNAME" "$FAIL"
if "$HEALTH" "$PORT" 15 1; then
  log "[$ENVNAME] release $VERSION is live"
else
  log "[$ENVNAME] health check FAILED for $VERSION"
  if [ -n "$PREVIOUS" ]; then
    log "[$ENVNAME] auto-rollback -> $(basename "$PREVIOUS")"
    switch_current "$PREVIOUS"
    "$SERVICE" start "$ENVNAME" 0
    "$HEALTH" "$PORT" 15 1 || die "rollback also unhealthy"
  else
    "$SERVICE" stop "$ENVNAME"
    rm -f "$ENV_DIR/current"
  fi
  rm -rf "$REL_DIR"
  exit 1
fi

# Retention: keep only the newest N releases.
ls -1dt "$ENV_DIR"/releases/* 2>/dev/null | tail -n +"$((KEEP_RELEASES + 1))" | xargs -r rm -rf
