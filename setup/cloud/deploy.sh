#!/bin/bash

deploy_task() {
    echo "Docker auf der Cloud-VM vorbereiten..."
    remote_command "sudo bash -s" \
        < "${SCRIPT_DIR}/bootstrap.sh"

    echo "Projektordner auf der VM vorbereiten..."
    remote_command "mkdir -p /home/leon/bigdata"

    echo "Aufgaben und Setup auf die VM uebertragen..."
    gc compute scp --recurse \
        /workspace/data \
        /workspace/setup \
        "leon@${GCE_INSTANCE_NAME}:/home/leon/bigdata/" \
        --zone="$GCE_ZONE"

    echo "Aufgaben-Konfiguration auf der VM pruefen..."
    remote_command "sudo docker compose -f /home/leon/bigdata/data/compose.yml config --quiet"

    echo "Aufgabendateien wurden uebertragen und Compose ist gueltig."

    echo "Image fuer $TASK_SERVICE bauen..."
    remote_command "sudo env DOCKER_BUILDKIT=0 docker compose \
            -f /home/leon/bigdata/data/compose.yml \
            build $TASK_SERVICE"

    echo "Bisherige Aufgabencontainer stoppen..."
    remote_command "sudo docker compose \
            -f /home/leon/bigdata/data/compose.yml \
            --profile '*' stop --timeout 60"

    echo "$TASK_SERVICE starten..."
    remote_command "sudo docker compose \
            -f /home/leon/bigdata/data/compose.yml \
            up -d --no-build $TASK_SERVICE"

    echo "Status der Aufgabencontainer:"
    remote_command "sudo docker compose \
            -f /home/leon/bigdata/data/compose.yml \
            --profile '*' ps --all"
}
