# BigData

Hadoop-/Hive-Aufgaben lokal oder auf einer Google-Cloud-VM ausfuehren.

| Ordner | Verantwortung |
| --- | --- |
| `infra/` | Terraform: VM und SSH-Firewall; nutzt bestehendes Netzwerk/Subnetz |
| `setup/cloud/` | Controller: VM starten/stoppen, Docker vorbereiten, Aufgaben uebertragen/starten |
| `setup/hadoop/` | SSH, HDFS, YARN und Hive innerhalb der Aufgabencontainer starten |
| `data/` | Aufgaben, Dockerfiles und gemeinsame Aufgaben-Compose-Datei |
| `tests/` | Offline-Tests fuer Konfiguration, IP-Helfer und Controller |

Terraform ersetzt VM-Erstellung und Firewallverwaltung in Bash. Docker-Bootstrap
und Hadoop-Setup werden weiterhin benoetigt. `start.bat` entfaellt; lokal und
auf der VM werden dieselben Aufgaben ueber Compose gestartet.

## Cloud einmalig konfigurieren

Voraussetzungen: Terraform >= 1.13 und < 2, PowerShell, Docker/Compose sowie
aktivierte Compute Engine API. Der Service-Account braucht VM-/SSH-Rechte,
Lesezugriff auf Netzwerk/Subnetz und Rechte zur Firewallverwaltung inklusive
`compute.networks.updatePolicy`. Netzwerk, Subnetz, API und IAM werden nicht angelegt.

1. `infra/terraform.tfvars.json.example` nach `infra/terraform.tfvars.json`
   kopieren. Projekt, Region, Zone, VM-, Netzwerk-, Subnetz- und Firewallnamen
   anpassen. Standard: Debian 12, 40 GB, `e2-standard-2`, Stopp nach zwei Stunden.
2. `.env` anlegen; alte `GOOGLE_CLOUD_PROJECT_ID`-/`GCE_*`-Werte entfallen:

   ```dotenv
   GCP_KEY_FILE=C:/pfad/zum/gcp-key.json
   TASK_SERVICE=task02
   ```

3. In PowerShell denselben Schluessel fuer Terraform setzen:

   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS = 'C:/pfad/zum/gcp-key.json'
   .\infra\update-ip.ps1
   terraform -chdir=infra init
   ```

Persoenliche JSON-Datei, IP-Datei, State und Plaene bleiben ausserhalb von Git;
`.terraform.lock.hcl` wird versioniert. Den lokalen State und dessen Backups
sicher aufbewahren: Terraform braucht ihn zur Zuordnung vorhandener Ressourcen.

## Bestehende VM und Firewall uebernehmen

Vor dem ersten Apply einmalig importieren, sofern die Ressourcen existieren
und noch nicht im Terraform-State stehen:

```powershell
$config = Get-Content ./infra/terraform.tfvars.json -Raw | ConvertFrom-Json
terraform -chdir=infra import google_compute_instance.bigdata "projects/$($config.project_id)/zones/$($config.zone)/instances/$($config.instance_name)"
terraform -chdir=infra import google_compute_firewall.ssh "projects/$($config.project_id)/global/firewalls/$($config.firewall_name)"
```

Fehlende Ressourcen nicht importieren; Terraform erstellt sie beim Apply.
Nach dem Import den Plan pruefen und Disk-, Image- und Netzwerkeigenschaften
mit der bestehenden VM abgleichen. `prevent_destroy` blockiert deren Loeschen
oder Ersetzen, solange der Ressourcenblock besteht. Konfigurationsupdates
koennen die VM stoppen; den Controller vorher beenden.

## Cloud starten und stoppen

Aus dem Projektverzeichnis, mit gesetztem `GOOGLE_APPLICATION_CREDENTIALS`:

```powershell
.\infra\update-ip.ps1
terraform -chdir=infra plan -out=changes.tfplan
terraform -chdir=infra show changes.tfplan
terraform -chdir=infra apply changes.tfplan
docker compose up --build -d
docker compose logs -f controller
```

Der IP-Helfer erzeugt `infra/runtime.auto.tfvars.json`: SSH auf Port 22 wird
nur fuer deine aktuelle IPv4 (`/32`) und VMs mit Tag `bigdata-ssh` freigegeben.
Bei IP-Wechsel IP-Helfer und Plan/Apply wiederholen; alte gespeicherte Plaene
enthalten noch die alte IP. `ssh_source_cidr` nicht zusaetzlich in die zentrale
JSON-Datei eintragen. Andere vorhandene Firewallregeln bleiben bestehen.

Der Controller liest dieselbe JSON-Datei schreibgeschuetzt, startet die VM,
wartet auf SSH, installiert bei Bedarf Docker/Compose und startet `TASK_SERVICE`.
Neue VMs laufen bereits nach Apply; anschliessend Aufgaben starten oder die VM
stoppen. Die VM besitzt keinen Service-Account und keine feste externe IP.

```powershell
docker compose stop
```

Das stoppt auch die vom Controller uebernommene VM. Daten und Ressourcen bleiben
erhalten. Bei einem Fehler nach VM-Uebernahme greift ebenfalls der Cleanup.

## Aufgaben lokal ausfuehren

```powershell
docker compose -f data/compose.yml up --build -d task02
docker compose -f data/compose.yml exec task02 su - hadoop
```

Fuer Aufgabe 03 `task03` verwenden. Vor einem Aufgabenwechsel:

```powershell
docker compose -f data/compose.yml --profile '*' stop
```

Beide Aufgaben teilen HDFS-/Hive-Volumes und Port 8088; jeweils nur eine starten.
YARN ist lokal unter http://localhost:8088 erreichbar. Aufgabe 03 startet nach
dem Hadoop-Setup zusaetzlich HiveServer2.

Als `hadoop` in Aufgabe 02:

```bash
bash /app/data/02_hive/download_imdb.sh
hive -f /app/data/02_hive/my_solution.sql
hive -e 'SELECT * FROM title_ratings LIMIT 10;'
```

## Lokal pruefen

```powershell
python -m unittest discover -s tests -v
terraform -chdir=infra fmt -check -recursive
terraform -chdir=infra validate
terraform -chdir=infra test
```

Die Tests simulieren Cloud-Aufrufe. Terraform-Tests brauchen den installierten
Provider (`terraform init`), aber keinen Cloud-Zugang. Bash und PowerShell sind
fuer die entsprechenden Python-Tests erforderlich; fehlen sie, werden diese
Tests uebersprungen.
