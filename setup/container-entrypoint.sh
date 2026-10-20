#!/bin/bash
set -Eeuo pipefail
rm -f /tmp/lab-ready
trap 'echo "FAILED at line $LINENO: $BASH_COMMAND" >&2' ERR
source /opt/lab/setup/configure-services.sh
run() { su - hadoop -c "set -Eeuo pipefail; source /etc/profile.d/lab.sh; $*"; }
source /opt/lab/setup/start-hadoop.sh
if [ "${USE_HIVE:-false}" = true ]; then
    source /opt/lab/setup/initialize-hive.sh
fi
# The task owns its dataset import and table definitions.
run 'bash /opt/lab/task/import.sh'
if [ "${START_HIVESERVER2:-false}" != true ]; then
    touch /tmp/lab-ready
    echo "READY. Work directory: /workspace"
fi
source /opt/lab/setup/run-services.sh
