#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
for module in config instance ssh deploy; do
    source "$SCRIPT_DIR/$module.sh"
done

load_config
authenticate
ensure_instance

# Ab hier stoppen auch Fehler und Stoppsignale die uebernommene VM.
trap stop_instance EXIT
trap 'exit 0' TERM INT

wait_for_ssh
deploy_task

echo "VM und Docker sind bereit."
echo "Zum Beenden: docker stop --time 120 bigdata-controller"

while true; do
    sleep 60 &
    wait $!
done
