#!/bin/bash
set -Eeuo pipefail
install -d -o hadoop -g hadoop /state /state/workspace /state/logs /state/namenode /state/datanode /run/sshd
ln -sfn /state/workspace /workspace
export HADOOP_LOG_DIR=/state/logs
cat > /home/hadoop/hadoop/etc/hadoop/core-site.xml <<'XML'
<configuration>
 <property><name>fs.defaultFS</name><value>hdfs://localhost:9000</value></property>
 <property><name>hadoop.tmp.dir</name><value>/state/tmp</value></property>
</configuration>
XML
cat > /home/hadoop/hadoop/etc/hadoop/hdfs-site.xml <<'XML'
<configuration>
 <property><name>dfs.replication</name><value>1</value></property>
 <property><name>dfs.namenode.name.dir</name><value>file:///state/namenode</value></property>
 <property><name>dfs.datanode.data.dir</name><value>file:///state/datanode</value></property>
 <property><name>dfs.namenode.datanode.registration.ip-hostname-check</name><value>false</value></property>
</configuration>
XML
cat > /home/hadoop/hadoop/etc/hadoop/yarn-site.xml <<'XML'
<configuration>
 <property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>
 <property><name>yarn.nodemanager.resource.memory-mb</name><value>6144</value></property>
 <property><name>yarn.scheduler.maximum-allocation-mb</name><value>6144</value></property>
 <property><name>yarn.nodemanager.vmem-check-enabled</name><value>false</value></property>
 <property><name>yarn.nodemanager.pmem-check-enabled</name><value>false</value></property>
</configuration>
XML
cat > /home/hadoop/hadoop/etc/hadoop/mapred-site.xml <<'XML'
<configuration>
 <property><name>mapreduce.framework.name</name><value>yarn</value></property>
 <property><name>yarn.app.mapreduce.am.env</name><value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop</value></property>
 <property><name>mapreduce.map.env</name><value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop</value></property>
 <property><name>mapreduce.reduce.env</name><value>HADOOP_MAPRED_HOME=/home/hadoop/hadoop</value></property>
</configuration>
XML
cat > /home/hadoop/hive/conf/hive-site.xml <<'XML'
<configuration>
 <property><name>javax.jdo.option.ConnectionURL</name><value>jdbc:derby:;databaseName=/state/metastore_db;create=true</value></property>
 <property><name>javax.jdo.option.ConnectionDriverName</name><value>org.apache.derby.jdbc.EmbeddedDriver</value></property>
 <property><name>hive.metastore.warehouse.dir</name><value>/user/hive/warehouse</value></property>
 <property><name>hive.metastore.schema.verification</name><value>true</value></property>
 <property><name>hive.server2.thrift.bind.host</name><value>0.0.0.0</value></property>
 <property><name>hive.server2.authentication</name><value>NONE</value></property>
 <property><name>hive.server2.enable.doAs</name><value>false</value></property>
 <property><name>hive.execution.engine</name><value>mr</value></property>
 <property><name>hive.exec.local.scratchdir</name><value>/state/hive-scratch</value></property>
 <property><name>hive.downloaded.resources.dir</name><value>/state/hive-resources</value></property>
</configuration>
XML
printf 'localhost\n' > /home/hadoop/hadoop/etc/hadoop/workers
ssh-keygen -A
/usr/sbin/sshd
# Hadoop start scripts require passwordless loopback SSH.
su - hadoop -c 'mkdir -p ~/.ssh; chmod 700 ~/.ssh; test -f ~/.ssh/id_rsa || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa; cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys; printf "Host localhost 127.0.0.1 0.0.0.0\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n" > ~/.ssh/config'
cat > /etc/profile.d/lab.sh <<'SH'
export HADOOP_HOME=/home/hadoop/hadoop HIVE_HOME=/home/hadoop/hive
export HADOOP_LOG_DIR=/state/logs
export PATH="$HIVE_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"
SH
