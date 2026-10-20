#!/bin/bash
set -e
export PATH="/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:$PATH"

# Nur neuen, leeren Speicher formatieren. Vorhandene Daten schuetzen.
name_dir=/home/hadoop/hadoopdata/hdfs/namenode
data_dir=/home/hadoop/hadoopdata/hdfs/datanode
if [ ! -f "$name_dir/current/VERSION" ]; then
    for dir in "$name_dir" "$data_dir"; do
        if [ -d "$dir" ] && [ -n "$(ls -A "$dir")" ]; then
            echo "Refusing to format non-empty HDFS storage: $dir" >&2
            exit 1
        fi
    done
    mkdir -p "$name_dir" "$data_dir"
    hdfs namenode -format -nonInteractive
fi

start-dfs.sh

# Erst fortfahren, wenn HDFS Anfragen beantworten kann.
for attempt in {1..30}; do
    if hdfs dfs -ls /; then
        exit 0
    fi
    sleep 2
done

echo "HDFS startup failed. NameNode log:" >&2
tail -n 80 /home/hadoop/hadoop/logs/*namenode*.log >&2
exit 1
