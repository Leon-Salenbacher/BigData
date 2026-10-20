#!/bin/bash

remote_command() {
    local command="$1"
    shift
    gc compute ssh "leon@$GCE_INSTANCE_NAME" \
        --zone="$GCE_ZONE" --command="$command" "$@"
}

wait_for_ssh() {
    local ssh_ready attempt
    echo "Auf SSH warten..."
    ssh_ready=false

    for attempt in {1..30}; do
        if remote_command "true" \
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
}
