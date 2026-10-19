#!/bin/bash
set -euo pipefail

# Ohne diese Einstellungen sofort mit einer Fehlermeldung abbrechen.
: "${GOOGLE_CLOUD_PROJECT_ID:?Projekt-ID fehlt}"
: "${GCE_INSTANCE_NAME:?VM-Name fehlt}"
: "${GCE_ZONE:?Zone fehlt}"
: "${GCE_NETWORK:?Netzwerk fehlt}"
: "${GCE_SUBNET:?Subnetz fehlt}"
: "${TASK_SERVICE:?Aufgabenservice fehlt}"


# Einstellungen mit Standardwerten.
GCE_MACHINE_TYPE="${GCE_MACHINE_TYPE:-e2-standard-2}"
GCE_MAX_RUN_DURATION="${GCE_MAX_RUN_DURATION:-2h}"

# Kurzform fuer gcloud mit unserem Projekt.
gc() {
    gcloud --quiet --project="$GOOGLE_CLOUD_PROJECT_ID" "$@"
}

echo "Bei Google Cloud anmelden..."
gc auth activate-service-account \
    --key-file=/secrets/gcp-key.json

# Nur unsere VM in unserer Zone suchen.
# Ein API- oder Berechtigungsfehler bricht das Skript ab.
status=$(gc compute instances list \
    --filter="name=$GCE_INSTANCE_NAME AND zone:($GCE_ZONE)" \
    --format="value(status)")

case "$status" in
    "")
        echo "VM erstellen..."
        gc compute instances create "$GCE_INSTANCE_NAME" \
            --zone="$GCE_ZONE" \
            --machine-type="$GCE_MACHINE_TYPE" \
            --image-family=debian-12 \
            --image-project=debian-cloud \
            --boot-disk-size=40GB \
            --boot-disk-type=pd-balanced \
            --network="$GCE_NETWORK" \
            --subnet="$GCE_SUBNET" \
            --tags=bigdata-ssh \
            --no-service-account \
            --no-scopes \
            --max-run-duration="$GCE_MAX_RUN_DURATION" \
            --instance-termination-action=STOP \
            --no-restart-on-failure
        ;;
    TERMINATED)
        echo "Vorhandene VM starten..."
        gc compute instances start "$GCE_INSTANCE_NAME" \
            --zone="$GCE_ZONE"
        ;;
    RUNNING)
        echo "VM laeuft bereits."
        ;;
    *)
        echo "VM ist im Zustand '$status'. Bitte spaeter erneut versuchen." >&2
        exit 1
        ;;
esac

# Ab jetzt uebernimmt dieser Container das Stoppen unserer VM.
cleanup() {
    echo "Cloud-VM stoppen..."
    if ! gc compute instances stop "$GCE_INSTANCE_NAME" \
        --zone="$GCE_ZONE"; then
        echo "Stopp fehlgeschlagen. Bitte den VM-Status in Google Cloud pruefen." >&2
    fi
}

trap cleanup EXIT
trap 'exit 0' TERM INT

echo "Auf SSH warten..."
ssh_ready=false

for attempt in {1..30}; do
    if gc compute ssh "leon@$GCE_INSTANCE_NAME" \
        --zone="$GCE_ZONE" \
        --command="true" \
        --ssh-flag="-o ConnectTimeout=5" \
        --ssh-flag="-o ConnectionAttempts=1"; then
        ssh_ready=true
        break
    fi
    sleep 5
done

if [ "$ssh_ready" != true ]; then
    echo "SSH nicht erreichbar. VM-Status und Firewall-Quell-IP pruefen." >&2
    exit 1
fi

echo "Docker auf der Cloud-VM vorbereiten..."
gc compute ssh "leon@$GCE_INSTANCE_NAME" \
    --zone="$GCE_ZONE" \
    --command="sudo bash -s" \
    < /controller/bootstrap.sh

echo "Projektordner auf der VM vorbereiten..."
gc compute ssh "leon@$GCE_INSTANCE_NAME" \
    --zone="$GCE_ZONE" \
    --command="mkdir -p /home/leon/bigdata"

echo "Aufgaben und Setup auf die VM uebertragen..."
gc compute scp --recurse \
    /workspace/data \
    /workspace/setup \
    "leon@${GCE_INSTANCE_NAME}:/home/leon/bigdata/" \
    --zone="$GCE_ZONE"

echo "Aufgaben-Konfiguration auf der VM pruefen..."
gc compute ssh "leon@$GCE_INSTANCE_NAME" \
    --zone="$GCE_ZONE" \
    --command="sudo docker compose -f /home/leon/bigdata/data/compose.yml config --quiet"

echo "Aufgabendateien wurden uebertragen und Compose ist gueltig."

echo "Image fuer $TASK_SERVICE bauen..."
gc compute ssh "leon@$GCE_INSTANCE_NAME" \
    --zone="$GCE_ZONE" \
    --command="sudo env DOCKER_BUILDKIT=0 docker compose \
        -f /home/leon/bigdata/data/compose.yml \
        build $TASK_SERVICE"

echo "Bisherige Aufgabencontainer stoppen..."
gc compute ssh "leon@$GCE_INSTANCE_NAME" \
    --zone="$GCE_ZONE" \
    --command="sudo docker compose \
        -f /home/leon/bigdata/data/compose.yml \
        --profile '*' stop --timeout 60"

echo "$TASK_SERVICE starten..."
gc compute ssh "leon@$GCE_INSTANCE_NAME" \
    --zone="$GCE_ZONE" \
    --command="sudo docker compose \
        -f /home/leon/bigdata/data/compose.yml \
        up -d --no-build $TASK_SERVICE"

echo "Status der Aufgabencontainer:"
gc compute ssh "leon@$GCE_INSTANCE_NAME" \
    --zone="$GCE_ZONE" \
    --command="sudo docker compose \
        -f /home/leon/bigdata/data/compose.yml \
        --profile '*' ps --all"

echo "VM und Docker sind bereit."
echo "Zum Beenden: docker stop --time 120 bigdata-controller"

# Container aktiv halten und auf Stoppsignale reagieren.
while true; do
    sleep 60 &
    wait $!
done