#!/bin/bash
# Sourced by container-entrypoint.sh; manages service lifetime.
if [ "${START_HIVESERVER2:-false}" = true ]; then
    run 'cd /state; exec hive --service hiveserver2' >>/state/logs/hiveserver2.log 2>&1 &
    server_pid=$!
    connected=false
    for attempt in {1..120}; do
        kill -0 "$server_pid" || { tail -n 80 /state/logs/hiveserver2.log; exit 1; }
        if run 'beeline -u jdbc:hive2://localhost:10000/default -n hadoop -e "SHOW TABLES;"'; then connected=true; break; fi
        sleep 5
    done
    $connected || exit 1
    touch /tmp/lab-ready
    trap 'kill -TERM "$server_pid" 2>/dev/null || true; run "stop-yarn.sh; stop-dfs.sh"; exit 0' TERM INT
    wait "$server_pid"
else
    trap 'run "stop-yarn.sh; stop-dfs.sh"; exit 0' TERM INT
    while true; do sleep 30 & wait $!; done
fi
