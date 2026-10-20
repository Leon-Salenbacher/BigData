#!/bin/bash
# Sourced by container-entrypoint.sh; uses run().
if [ ! -f /state/namenode/current/VERSION ]; then
    if [ -n "$(ls -A /state/namenode)$(ls -A /state/datanode)" ]; then
        echo 'Refusing to format nonempty HDFS storage.' >&2
        exit 1
    fi
    run 'hdfs namenode -format -nonInteractive'
fi
run 'start-dfs.sh && start-yarn.sh'
available=false
for attempt in {1..90}; do
    if run 'hdfs dfs -ls / && hdfs dfsadmin -safemode wait'; then available=true; break; fi
    sleep 3
done
$available || exit 1
run 'hdfs dfs -mkdir -p /user/hadoop /tmp && hdfs dfs -chmod 1777 /tmp'
