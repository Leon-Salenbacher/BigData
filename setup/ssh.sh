#!/bin/bash
set -e

# Laufzeitverzeichnis vorbereiten und SSH-Server starten (als root).
install -d -o root -g root -m 0755 /run/sshd
/usr/sbin/sshd
