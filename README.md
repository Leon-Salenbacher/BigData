# BigData

## .env
create a .env file with your project id
```
GOOGLE_CLOUD_PROJECT_ID=[google cloud project id]
```

## start 
docker run -it \
    --name bigdata \
    --env-file .env \
    -p 8080:8080 \
    bigdata-exercises-image



## get bash 
```docker exec -it bigdata bash```


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


## start DFS and YARN
```start-all.sh````
