FROM marcelmittelstaedt/hiveserver_base:latest
USER root
ENV TASK=03
ENV USE_HIVE=true
ENV START_HIVESERVER2=true
ENV HADOOP_HOME=/home/hadoop/hadoop
ENV HIVE_HOME=/home/hadoop/hive
ENV PATH=/home/hadoop/hive/bin:/home/hadoop/hadoop/bin:/home/hadoop/hadoop/sbin:$PATH
COPY setup/ /opt/lab/setup/
COPY data/03-hive-server/ /opt/lab/task/
RUN chmod +x /opt/lab/setup/*.sh /opt/lab/task/*.sh
WORKDIR /home/hadoop
ENTRYPOINT ["/bin/bash", "/opt/lab/setup/container-entrypoint.sh"]
