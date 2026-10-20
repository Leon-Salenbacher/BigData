# Big-Data-Lab mit Terraform

Terraform erstellt eine Google-Cloud-VM mit eigenem Netzwerk und einer SSH-Firewallregel fuer deine IP. Beim ersten Start installiert die VM Docker, baut die drei Dockerfiles und bereitet die Daten vor. Kein Python-Controller.

```text
.
|-- main.tf
|-- variables.tf
|-- outputs.tf
|-- versions.tf
|-- terraform.tfvars.example
|-- compose.yml
|-- data/
|   |-- 01-hadoop/
|   |   |-- Dockerfile
|   |   |-- download.sh
|   |   `-- import.sh
|   |-- 02-hive/
|   |   |-- Dockerfile
|   |   |-- download.sh
|   |   |-- import.sh
|   |   `-- schema.sql
|   `-- 03-hive-server/
|       |-- Dockerfile
|       |-- download.sh
|       |-- import.sh
|       `-- schema.sql
`-- setup/
    |-- startup.sh
    |-- container-entrypoint.sh
    |-- configure-services.sh
    |-- start-hadoop.sh
    |-- initialize-hive.sh
    `-- run-services.sh
```

## Starten

Voraussetzungen: Terraform >= 1.5, Google Cloud CLI, ein Cloud-Projekt mit Abrechnung und Berechtigungen zum Aktivieren der Compute API und Erstellen von VM, Netzwerk und Firewall.

```powershell
gcloud auth application-default login
gcloud auth login
Copy-Item terraform.tfvars.example terraform.tfvars
```

In `terraform.tfvars` deine `project_id` und deine oeffentliche IPv4 als `allowed_ip = "1.2.3.4/32"` eintragen. Dann:

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Standard: Frankfurt, `n2-highmem-4`, 200 GB Disk. `apply` erstellt kostenpflichtige Ressourcen. Das Ende von `apply` bedeutet, dass die VM erstellt ist; Downloads und Container-Einrichtung laufen danach weiter. Den Befehl aus `terraform output -raw status` ausfuehren. `READY` bedeutet, dass alle drei Container vorbereitet sind. Einrichtung kann mehrere Minuten dauern.

## Aufgabencontainer

- `bigdata-task01`: Java, Hadoop, HDFS, YARN und Faust_1.txt fuer MapReduce.
- `bigdata-task02`: Hive CLI, IMDb-Daten und externe Basistabellen.
- `bigdata-task03`: HiveServer2 mit eigenem HDFS/Metastore, IMDb-Daten und Basistabellen fuer Partitionierung.

Die Docker-Builds verwenden das Projektverzeichnis als Kontext. Die beiden Hive-Datensaetze werden unabhaengig in HDFS geladen; Downloads werden gemeinsam gecacht. Abfragen und Partitionierungsaufgaben kannst du selbst bearbeiten. Die Images entsprechen den Kursimages und verwenden deren `latest`-Tag.

Die allgemeine Einrichtung liegt ausschliesslich unter `setup/`: VM/Docker aufbauen, Dienste konfigurieren, Hadoop starten, bei Bedarf den Hive-Metastore initialisieren und die Dienste betreiben. Die Aufgaben liefern zwei eigene Skripte:

- `data/<task>/download.sh`: laeuft auf der VM und laedt die benoetigten Dateien in den gemeinsamen Cache. Bereits vorhandene Downloads werden wiederverwendet.
- `data/<task>/import.sh`: laeuft im jeweiligen Container als `hadoop`, nachdem die benoetigten Dienste bereit sind. Es importiert die Daten in das eigene HDFS und erstellt gegebenenfalls die Tabellen aus der zugehoerigen `schema.sql`.

`setup/startup.sh` ruft die Download-Skripte auf; `setup/container-entrypoint.sh` ruft das in das Image kopierte Import-Skript auf. Aufgabenbezogene URLs, Dateinamen, HDFS-Ziele und SQL-Imports stehen in den jeweiligen Aufgabenordnern.

Den Befehl aus `terraform output -raw ssh` ausfuehren. Auf der VM:

```bash
sudo docker exec -it -u hadoop -w /state/workspace bigdata-task01 bash -l
sudo docker exec -it -u hadoop -w /state/workspace bigdata-task02 bash -l
sudo docker exec -it -u hadoop -w /state/workspace bigdata-task03 bash -l
```

Eigene Dateien in `/state/workspace` speichern. Teil 02: `hive`. Teil 03: `beeline -u jdbc:hive2://localhost:10000/default -n hadoop`. Dort nicht gleichzeitig die Hive CLI starten, da der eingebettete Derby-Metastore nur einen Prozess zulaesst.

Den Befehl aus `terraform output -raw hive_tunnel` in einem weiteren Terminal starten und offen lassen. Dann erreichst du Teil 03 unter <http://localhost:8088>, <http://localhost:9870> und via JDBC unter `jdbc:hive2://localhost:10000/default` (Nutzer `hadoop`, kein Passwort). Fuer Teil 01/02 die Tunnel-Zielports entsprechend `compose.yml` aendern. Manche Links der Hadoop-Oberflaechen enthalten interne Containernamen und sind ueber den Tunnel nicht direkt erreichbar.

## Betrieb

Nur SSH ist von der angegebenen `/32`-Adresse erreichbar. Alle veroeffentlichten Containerports sind auf der VM an localhost gebunden. Bei einem Wechsel deiner IP `allowed_ip` anpassen und erneut `terraform apply` ausfuehren.

Einrichtungslogs: `/var/log/bigdata-setup.log`. Containerlogs: `sudo docker logs bigdata-task03`. Nach einem behobenen Einrichtungsfehler kannst du auf der VM mit `sudo systemctl restart --no-block google-startup-scripts.service` erneut starten.

Zum Pausieren die VM in Google Cloud stoppen; Speicher kostet weiterhin. Nach einem Neustart startet das Startup-Skript die Container mit vorhandenen Daten. Aenderungen an den Dockerfiles oder Einrichtungsskripten werden mit `terraform apply` in den VM-Metadaten aktualisiert und beim naechsten VM-Start angewendet. Zum direkten Anwenden auf einer laufenden VM den obigen Neustart der Startup-Service verwenden.

`terraform destroy` entfernt VM, Bootdisk und Netzwerk; dabei werden auch die Daten der Container geloescht. Dateien vorher sichern.

Ein vollstaendiger Cloud-Lauf und der Docker-Build sind hier noch nicht bestaetigt.

Referenz: [Google Compute Instance im Terraform-Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance).
