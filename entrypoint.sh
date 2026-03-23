#!/usr/bin/env bash
set -e

TEAM_NAME="${TEAM_NAME:-}"
PROXY_PORT="${PROXY_PORT:-}"
TOKEN="${CF_REGISTRATION_TOKEN:-}"

require_env() {
    local name="$1"
    local value="$2"

    if [ -z "$value" ]; then
        echo "[ERROR] Required environment variable '$name' is missing."
        exit 1
    fi
}

require_real_value() {
    local name="$1"
    local value="$2"

    case "$value" in
        team-name|your-token|REPLACE_WITH_*|CHANGEME|changeme)
            echo "[ERROR] Environment variable '$name' is still using a placeholder value: $value"
            exit 1
            ;;
    esac
}

require_port() {
    local value="$1"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "[ERROR] PROXY_PORT must be a numeric port."
        exit 1
    fi

    if [ "$value" -lt 1 ] || [ "$value" -gt 65535 ]; then
        echo "[ERROR] PROXY_PORT must be between 1 and 65535."
        exit 1
    fi
}

require_cmd() {
    local name="$1"

    if ! command -v "$name" >/dev/null 2>&1; then
        echo "[ERROR] Required command '$name' not found in container."
        exit 1
    fi
}

wait_for_listen() {
    local port="$1"
    local name="$2"
    local retries="${3:-20}"
    local i

    for i in $(seq 1 "$retries"); do
        if ss -lntp 2>/dev/null | grep -q ":${port} "; then
            echo "[INFO] ${name} is listening on :${port}"
            return 0
        fi
        sleep 1
    done

    echo "[ERROR] ${name} failed to listen on :${port}"
    ss -lntp || true
    return 1
}

require_env "TEAM_NAME" "$TEAM_NAME"
require_env "PROXY_PORT" "$PROXY_PORT"
require_env "CF_REGISTRATION_TOKEN" "$TOKEN"

require_real_value "TEAM_NAME" "$TEAM_NAME"
require_real_value "PROXY_PORT" "$PROXY_PORT"
require_real_value "CF_REGISTRATION_TOKEN" "$TOKEN"

require_port "$PROXY_PORT"
require_cmd "warp-svc"
require_cmd "warp-cli"
require_cmd "socat"
require_cmd "gost"

echo "[INFO] Starting warp-svc..."
warp-svc >/dev/null 2>&1 &

sleep 5

WARP="warp-cli --accept-tos"

echo "[INFO] Checking registration..."

if ! $WARP registration show 2>/dev/null | grep -qi "organization"; then
    echo "[INFO] Not registered"
    echo "[INFO] Using registration token"
    $WARP registration new "$TEAM_NAME" || true
    $WARP registration token "$TOKEN"
fi

echo "[INFO] Registration OK"
$WARP registration show || true

echo "[INFO] Setting proxy port: $PROXY_PORT"
$WARP proxy port "$PROXY_PORT" || true

echo "[INFO] Connecting..."
$WARP connect || true

echo "[INFO] gost version:"
gost -V || true

# HTTP forwarder
echo "[INFO] Starting HTTP forwarder 40001 -> 127.0.0.1:${PROXY_PORT}"
socat -d -d TCP-LISTEN:40001,fork,bind=0.0.0.0 TCP:127.0.0.1:${PROXY_PORT} &
wait_for_listen "40001" "HTTP forwarder"

# SOCKS5 bridge
echo "[INFO] Starting SOCKS5 on :40008 -> HTTP proxy"
gost -L socks5://0.0.0.0:40008 -F http://127.0.0.1:${PROXY_PORT} &
wait_for_listen "40008" "SOCKS5 bridge"

echo "[INFO] Status:"
$WARP status || true

echo ""
echo "========================================"
echo "HTTP Proxy:   http://127.0.0.1:40001"
echo "SOCKS5 Proxy: socks5://127.0.0.1:40008"
echo "========================================"

tail -f /dev/null
