#!/bin/bash
set -e

# SSH braucht root; die anderen Komponenten laufen als hadoop.
bash /app/setup/ssh.sh
su - hadoop -c 'bash /app/setup/hdfs.sh'
su - hadoop -c 'bash /app/setup/yarn.sh'
su - hadoop -c 'bash /app/setup/hive.sh'

echo "BigData environment ready."
exec su - hadoop
