#!/bin/bash
# Runs inside the container as hadoop, after HDFS is ready.
set -Eeuo pipefail
java -version
javac -version
ls "$HADOOP_HOME"/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar
hdfs dfs -mkdir -p /user/hadoop/input
if ! hdfs dfs -test -s /user/hadoop/input/Faust_1.txt; then
    hdfs dfs -put -f /datasets/Faust_1.txt /user/hadoop/input/Faust_1.txt
fi
# Preserve the user's working copy on subsequent starts.
if [ ! -e /workspace/Faust_1.txt ]; then
    cp /datasets/Faust_1.txt /workspace/
fi
