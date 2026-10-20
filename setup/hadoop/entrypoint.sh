#!/bin/bash
set -e

# Speicherverzeichnisse fuer den Hadoop-Benutzer vorbereiten.
install -d -o hadoop -g hadoop \
    /home/hadoop/hadoopdata/hdfs/namenode \
    /home/hadoop/hadoopdata/hdfs/datanode \
    /var/lib/hive

# Hive auf den dauerhaften Metastore verweisen lassen.
sed -i \
    's|/home/hadoop/hive/metastore_db|/var/lib/hive/metastore_db|g' \
    /home/hadoop/hive/conf/hive-site.xml

# SSH braucht root; die anderen Komponenten laufen als hadoop.
bash /app/setup/ssh.sh
su - hadoop -c 'bash /app/setup/hdfs.sh'
su - hadoop -c 'bash /app/setup/yarn.sh'
su - hadoop -c 'bash /app/setup/hive.sh'

if [ "${START_HIVESERVER2:-false}" = "true" ]; then
    echo "Hadoop ist bereit. HiveServer2 wird gestartet..."
    exec su - hadoop -c \
        'exec /home/hadoop/hive/bin/hive --service hiveserver2'
fi

echo "BigData environment ready."
exec su - hadoop
