#!/bin/bash
# Runs inside the container as hadoop, after HDFS and the metastore are ready.
set -Eeuo pipefail
for dataset in title.basics title.ratings name.basics; do
    table="${dataset//./_}"
    target="/user/hadoop/imdb/$table"
    if ! hdfs dfs -test -s "$target/$dataset.tsv"; then
        hdfs dfs -mkdir -p "$target"
        gzip -dc "/datasets/$dataset.tsv.gz" | hdfs dfs -put -f - "$target/.$dataset.upload"
        hdfs dfs -mv "$target/.$dataset.upload" "$target/$dataset.tsv"
    fi
done
cd /state
hive -f /opt/lab/task/schema.sql
