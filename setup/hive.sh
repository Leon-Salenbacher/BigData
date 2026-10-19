#!/bin/bash
set -e
export PATH="/home/hadoop/hive/bin:$PATH"

# Lokalen Metastore einmalig anlegen und anschliessend pruefen.
if [ ! -d /home/hadoop/hive/metastore_db ]; then
    schematool -dbType derby -initSchema
fi
schematool -dbType derby -info
