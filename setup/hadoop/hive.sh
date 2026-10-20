#!/bin/bash
set -e

export PATH="/home/hadoop/hive/bin:$PATH"

# HDFS laeuft bereits, wenn dieses Skript aufgerufen wird.
/home/hadoop/hadoop/bin/hdfs dfs -mkdir -p \
    /tmp \
    /user/hive/warehouse \
    /user/hadoop

/home/hadoop/hadoop/bin/hdfs dfs -chmod g+w \
    /tmp \
    /user/hive/warehouse

# Nur eine noch nicht vorhandene Datenbank initialisieren.
if [ ! -d /var/lib/hive/metastore_db ]; then
    schematool -dbType derby -initSchema
fi

# Vorhandenes Schema pruefen; bei Fehlern abbrechen.
schematool -dbType derby -info

