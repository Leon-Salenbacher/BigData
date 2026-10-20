#!/bin/bash

ensure_instance() {
    local status
    # Nur unsere VM in unserer Zone suchen.
    # Ein API- oder Berechtigungsfehler bricht das Skript ab.
    status=$(gc compute instances list \
        --filter="name=$GCE_INSTANCE_NAME AND zone:($GCE_ZONE)" \
        --format="value(status)")

    case "$status" in
        "")
            echo "VM fehlt. Zuerst die Infrastruktur mit Terraform plan und apply bereitstellen." >&2
            exit 1
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
}

stop_instance() {
    echo "Cloud-VM stoppen..."
    if ! gc compute instances stop "$GCE_INSTANCE_NAME" \
        --zone="$GCE_ZONE"; then
        echo "Stopp fehlgeschlagen. Bitte den VM-Status in Google Cloud pruefen." >&2
    fi
}
