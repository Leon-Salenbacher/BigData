FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:stable

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /controller

COPY entrypoint.sh bootstrap.sh ./

# Windows-Zeilenenden in Linux-Zeilenenden umwandeln.
RUN sed -i 's/\r$//' entrypoint.sh bootstrap.sh

ENTRYPOINT ["bash", "/controller/entrypoint.sh"]