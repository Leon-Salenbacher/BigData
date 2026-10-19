FROM marcelmittelstaedt/hiveserver_base:latest

USER root
WORKDIR /app

COPY --chown=hadoop:hadoop ./data /app/data
COPY ./setup /app/setup

RUN sed -i 's/\r$//' /app/setup/*.sh \
    && chmod +x /app/setup/entrypoint.sh

ENV HADOOP_HOME=/home/hadoop/hadoop
ENV PATH="${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${PATH}"

ENTRYPOINT ["/app/setup/entrypoint.sh"]