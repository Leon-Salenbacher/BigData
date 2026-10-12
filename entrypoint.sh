#!/bin/bash
set -e

echo "========================================"
echo " Starting SSH"
echo "========================================"

# /run is runtime state and may be empty when the container starts.
install -d -o root -g root -m 0755 /run/sshd
/usr/sbin/sshd

echo "SSH started."

echo ""
echo "========================================"
echo " Testing SSH as Hadoop user"
echo "========================================"

su - hadoop -c "ssh -o StrictHostKeyChecking=no localhost whoami"

echo ""
echo "========================================"
echo " Starting Hadoop"
echo "========================================"

# Initialize only a new, empty HDFS. Never overwrite existing metadata.
su - hadoop -c '
set -e
name_dir=/home/hadoop/hadoopdata/hdfs/namenode
data_dir=/home/hadoop/hadoopdata/hdfs/datanode
if [ ! -f "$name_dir/current/VERSION" ]; then
    for dir in "$name_dir" "$data_dir"; do
        if [ -d "$dir" ] && [ -n "$(ls -A "$dir")" ]; then
            echo "HDFS metadata is missing but storage is not empty: $dir" >&2
            echo "Refusing to format existing data." >&2
            exit 1
        fi
    done
    mkdir -p "$name_dir" "$data_dir"
    /home/hadoop/hadoop/bin/hdfs namenode -format -nonInteractive
fi
/home/hadoop/hadoop/sbin/start-dfs.sh
/home/hadoop/hadoop/sbin/start-yarn.sh
'

echo "Waiting for HDFS..."
hdfs_ready=false
for attempt in {1..30}; do
    if su - hadoop -c "/home/hadoop/hadoop/bin/hdfs dfs -ls /"; then
        hdfs_ready=true
        break
    fi
    sleep 2
done
if [ "$hdfs_ready" != true ]; then
    echo "HDFS startup failed. NameNode log:" >&2
    tail -n 80 /home/hadoop/hadoop/logs/*namenode*.log >&2
    exit 1
fi

# The base image also ships without an initialized local Hive metastore.
su - hadoop -c '
set -e
if [ ! -d /home/hadoop/hive/metastore_db ]; then
    /home/hadoop/hive/bin/schematool -dbType derby -initSchema
fi
/home/hadoop/hive/bin/schematool -dbType derby -info
'

echo ""
echo "========================================"
echo " Hadoop processes"
echo "========================================"

su - hadoop -c "jps"

echo ""
echo "========================================"
echo " BigData environment ready"
echo "========================================"

exec su - hadoop
