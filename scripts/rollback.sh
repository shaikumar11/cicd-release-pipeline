#!/usr/bin/env bash
# Usage: rollback.sh <env>  -- manually point `current` at the previous release.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ENVNAME="${1:?environment required}"
ENV_DIR="$DEPLOY_ROOT/$ENVNAME"
PORT="$(port_for_env "$ENVNAME")"

current="$(basename "$(readlink "$ENV_DIR/current")")"
previous="$(ls -1t "$ENV_DIR/releases" | grep -vx "$current" | head -n1 || true)"
[ -n "$previous" ] || die "no previous release to roll back to"

log "[$ENVNAME] rollback $current -> $previous"
ln -sfn "$ENV_DIR/releases/$previous" "$ENV_DIR/current.tmp" && mv -Tf "$ENV_DIR/current.tmp" "$ENV_DIR/current"
"$ROOT_DIR/scripts/service.sh" start "$ENVNAME" 0
"$ROOT_DIR/scripts/healthcheck.sh" "$PORT" 15 1
