#!/bin/bash

load_config() {
    : "${TASK_SERVICE:?Aufgabenservice fehlt}"
    local values
    local -a fields
    values=$(python3 "$SCRIPT_DIR/read-config.py" /config/terraform.tfvars.json)
    mapfile -t fields <<< "$values"
    GOOGLE_CLOUD_PROJECT_ID="${fields[0]}"
    GCE_INSTANCE_NAME="${fields[1]}"
    GCE_ZONE="${fields[2]}"
}

gc() {
    gcloud --quiet --project="$GOOGLE_CLOUD_PROJECT_ID" "$@"
}

authenticate() {
    echo "Bei Google Cloud anmelden..."
    gc auth activate-service-account --key-file=/secrets/gcp-key.json
}
