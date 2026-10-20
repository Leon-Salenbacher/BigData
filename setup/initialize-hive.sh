#!/bin/bash
# Sourced by container-entrypoint.sh; uses run().
run 'hdfs dfs -mkdir -p /user/hive/warehouse && hdfs dfs -chmod g+w /user/hive/warehouse'
if [ ! -d /state/metastore_db ]; then
    run 'schematool -dbType derby -initSchema'
fi
run 'schematool -dbType derby -info'
