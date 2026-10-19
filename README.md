# BigData

## .env
create a .env file with your project id
```
GOOGLE_CLOUD_PROJECT_ID=[google cloud project id]
```

## Start (Windows)
```powershell
.\start.bat
```
Das Skript baut das Image und ersetzt den bisherigen Container. Daten im
alten Container gehen dabei verloren. SSH, HDFS, YARN und der lokale
Hive-Metastore werden automatisch vorbereitet; danach startet eine Shell
als `hadoop`. Die YARN-Oberflaeche ist unter http://localhost:8088 erreichbar.

Einen vorhandenen Container ohne Neubau oder Loeschen wieder starten:
```powershell
docker start -ai bigdata
```



## get bash 
```docker exec -it bigdata su - hadoop```

## Aufbau des Containerstarts
`setup/entrypoint.sh` ruft die Komponenten der Reihe nach auf. Schlaegt ein
Schritt fehl, bricht der Start ab.

| Datei | Benutzer | Aufgabe |
| --- | --- | --- |
| `ssh.sh` | root | SSH-Server vorbereiten und starten |
| `hdfs.sh` | hadoop | Leeres HDFS initialisieren, starten und auf Erreichbarkeit warten |
| `yarn.sh` | hadoop | Hadoop-Ressourcenverwaltung starten |
| `hive.sh` | hadoop | Lokalen Hive-Metastore anlegen und pruefen |

Alle diese Skripte liegen gemeinsam in `setup/`.

Danach oeffnet der Entrypoint eine Shell als `hadoop`.
`start.bat` baut mit `data/02_hive/dockerfile` und dem Projektordner als
Build-Kontext. Nach Aenderungen an den Skripten muss das Image neu gebaut werden.

## Gemeinsames Setup und neue Aufgaben
```text
setup/                  Gemeinsamer Start von SSH, HDFS, YARN und Hive
data/
  02_hive/              Dockerfile und Dateien fuer Aufgabe 02
  03_hive-ql_partitioning_hive-server/
                        Dockerfile und Dateien fuer Aufgabe 03
start.bat               Baut und startet aktuell Aufgabe 02
```

Fuer eine neue Aufgabe legst du einen weiteren nummerierten Ordner unter
`data/` an. Die gemeinsamen Skripte bleiben in `setup/` und werden nicht
pro Aufgabe kopiert. Im Dockerfile einer Aufgabe mit kompatiblem Hadoop-/Hive-
Basis-Image bindest du sie so ein:

```dockerfile
COPY ./setup /app/setup
RUN chmod +x /app/setup/entrypoint.sh
USER root
ENTRYPOINT ["/app/setup/entrypoint.sh"]
```

Baue dabei immer vom Projektordner aus, zum Beispiel:
```powershell
docker build -f data/02_hive/dockerfile -t bigdata-exercises-image .
```

Das Basis-Image liefert die installierten Programme. `setup/` uebernimmt
deren Vorbereitung und Start. Das Dockerfile von Aufgabe 03 verwendet ein
anderes Basis-Image und behaelt vorerst dessen eigenen Startablauf; das
gemeinsame Setup startet keinen HiveServer2.


# Hive
## IMDb-Daten herunterladen und nach HDFS laden
Als `hadoop` in der Container-Shell ausfuehren:
```bash
bash /app/data/02_hive/download_imdb.sh
hive -f /app/data/02_hive/my_solution.sql
hive -e 'SELECT * FROM title_ratings LIMIT 10;'
```
Das Skript laedt `title.basics` und `title.ratings` von IMDb und importiert
sie in die HDFS-Verzeichnisse der externen Tabellen. Bereits vorhandene
Dateien werden uebersprungen.

## start
```hive```

## run sql file in hive
```hive -f file.sql```

## switch to hadoop user
```sudo su hadoop```


DFS und YARN starten bereits automatisch mit dem Container.
