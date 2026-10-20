#!/bin/bash
set -Eeuo pipefail
mkdir -p /var/lib/bigdata /opt/bigdata
exec >>/var/log/bigdata-setup.log 2>&1
exec 9>/var/lib/bigdata/setup.lock
flock -n 9 || exit 0
trap 'code=$?; if [ "$code" -ne 0 ]; then echo "FAILED exit $code, line $LINENO: $BASH_COMMAND" > /var/lib/bigdata/status; fi' EXIT
echo INSTALLING > /var/lib/bigdata/status
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y docker.io docker-compose curl git gzip
systemctl enable --now docker
@@FILES@@
cd /opt/bigdata
mkdir -p cache
echo DOWNLOADING > /var/lib/bigdata/status
# Each task declares and downloads its own input data.
for task_dir in data/*/; do
    if [ -f "$task_dir/download.sh" ]; then
        bash "$task_dir/download.sh" /opt/bigdata/cache
    fi
done
echo BUILDING > /var/lib/bigdata/status
docker-compose -f compose.yml build
docker-compose -f compose.yml up -d
echo INITIALIZING > /var/lib/bigdata/status
deadline=$((SECONDS + 3600))
while (( SECONDS < deadline )); do
    ready=0
    for task in 01 02 03; do
        state="$(docker inspect --format '{{.State.Status}}' "bigdata-task$task")"
        if [ "$state" = exited ] || [ "$state" = dead ]; then
            docker logs --tail 100 "bigdata-task$task"
            echo "Container task$task failed" >&2
            exit 1
        fi
        if docker exec "bigdata-task$task" test -f /tmp/lab-ready; then
            ready=$((ready + 1))
        fi
    done
    if [ "$ready" = 3 ]; then
        echo READY > /var/lib/bigdata/status
        echo "Alle drei Aufgabencontainer sind bereit."
        exit 0
    fi
    sleep 15
done
echo 'Timeout: Containerlogs pruefen.' >&2
exit 1
