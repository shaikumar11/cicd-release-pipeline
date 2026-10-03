#!/usr/bin/env bash
# Usage: service.sh start|stop <env> [fail_health]
# Starts/stops the app from the env's `current` release using a pid file.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ACTION="${1:?start|stop}"; ENVNAME="${2:?env}"; FAIL="${3:-0}"
ENV_DIR="$DEPLOY_ROOT/$ENVNAME"
PID_FILE="$ENV_DIR/app.pid"

stop_app() {
  if [ -f "$PID_FILE" ]; then
    pid="$(cat "$PID_FILE")"
    kill "$pid" 2>/dev/null || true
    for _ in $(seq 1 20); do kill -0 "$pid" 2>/dev/null || break; sleep 0.2; done
    kill -9 "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
}

case "$ACTION" in
  stop) stop_app ;;
  start)
    stop_app
    [ -L "$ENV_DIR/current" ] || die "no current release for $ENVNAME"
    version="$(basename "$(readlink "$ENV_DIR/current")")"
    cd "$ENV_DIR/current"
    APP_VERSION="$version" APP_ENV="$ENVNAME" APP_FAIL_HEALTH="$FAIL" \
      nohup python3 -m uvicorn app.main:app --host 127.0.0.1 \
      --port "$(port_for_env "$ENVNAME")" >"$ENV_DIR/app.log" 2>&1 &
    echo $! >"$PID_FILE"
    ;;
  *) die "usage: service.sh start|stop <env>" ;;
esac
