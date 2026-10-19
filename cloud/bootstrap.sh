#!/bin/bash
set -euo pipefail

# Docker nur installieren, wenn es noch fehlt.
if ! command -v docker >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io
fi

# Docker sofort starten und bei weiteren VM-Starts aktivieren.
systemctl enable --now docker

docker --version