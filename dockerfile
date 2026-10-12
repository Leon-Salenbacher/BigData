FROM marcelmittelstaedt/hive_base:latest

# my data
WORKDIR /app

COPY --chown=hadoop:hadoop ./data /app/data
COPY ./entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

# Hadoop env
ENV HADOOP_HOME=/home/hadoop/hadoop
ENV PATH="${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${PATH}"

USER root

ENTRYPOINT ["/app/entrypoint.sh"]

