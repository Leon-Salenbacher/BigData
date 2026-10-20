FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:stable

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-client python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /controller

COPY *.sh read-config.py ./

# Windows-Zeilenenden in Linux-Zeilenenden umwandeln.
RUN sed -i 's/\r$//' *.sh

ENTRYPOINT ["bash", "/controller/entrypoint.sh"]
