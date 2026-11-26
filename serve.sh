#!/usr/bin/env bash
# Start a local web server for the battery and open it in the browser.
#
# Usage:
#   ./serve.sh day=0|1|2
#   ./serve.sh task=effort|rlwm|foraging|gonogo
#
# For local testing only. Pavlovia does not use this script.

set -euo pipefail

usage() {
    echo "Usage: $0 day=0|1|2"
    echo "       $0 task=effort|rlwm|foraging|gonogo"
    exit 1
}

[ $# -eq 1 ] || usage

case "$1" in
    day=0|day=1|day=2) ;;
    task=effort|task=rlwm|task=foraging|task=gonogo) ;;
    *) echo "Invalid parameter: $1"; usage ;;
esac

command -v python3 >/dev/null || { echo "python3 is required but was not found."; exit 1; }

# Serve the folder this script lives in, regardless of where it is called from.
ROOT="$(cd "$(dirname "$0")" && pwd)"

# Find a free port, starting at 8000.
port_free() {
    python3 -c "import socket,sys; s=socket.socket(); s.bind(('127.0.0.1', $1))" 2>/dev/null
}
PORT=8000
while ! port_free "$PORT"; do
    PORT=$((PORT + 1))
    [ "$PORT" -le 8100 ] || { echo "No free port found between 8000 and 8100."; exit 1; }
done

# Bind to 127.0.0.1 so the server is reachable only from this machine.
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$ROOT" &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null' EXIT INT TERM

# Wait until the server accepts connections.
for _ in $(seq 1 50); do
    python3 -c "import socket; socket.create_connection(('127.0.0.1', $PORT), 0.2)" 2>/dev/null && break
    sleep 0.1
done

URL="http://localhost:$PORT/index.html?$1"
echo
echo "Battery running at: $URL"
echo "Press Ctrl+C to stop the server."
echo

if command -v open >/dev/null; then
    open "$URL"            # macOS
elif command -v xdg-open >/dev/null; then
    xdg-open "$URL"        # Linux
else
    echo "Open the URL above in your browser."
fi

wait "$SERVER_PID"
