#!/bin/bash
set -euo pipefail

# Docker bei Bedarf installieren.
if ! command -v docker >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io
fi

systemctl enable --now docker

# Compose bei Bedarf als Docker-Plugin installieren.
if ! docker compose version >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates curl

    compose_version="v2.39.4"
    plugin_dir="/usr/local/lib/docker/cli-plugins"
    download_file=$(mktemp)

    curl --fail --show-error --location \
        "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-x86_64" \
        --output "$download_file"

    install -d "$plugin_dir"
    install -m 0755 "$download_file" "$plugin_dir/docker-compose"
    rm "$download_file"
fi

docker --version
docker compose version