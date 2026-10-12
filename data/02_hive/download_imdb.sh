#!/bin/bash
set -euo pipefail

# Run as hadoop. Keep downloads outside the SQL directory.
download_dir="${IMDB_DOWNLOAD_DIR:-/home/hadoop/imdb-downloads}"
mkdir -p "$download_dir"
hdfs dfs -ls / >/dev/null
hdfs dfsadmin -safemode wait

for dataset in title.basics title.ratings; do
    table="${dataset//./_}"
    target="/user/hadoop/imdb/$table"
    filename="$dataset.tsv"
    if hdfs dfs -test -s "$target/$filename"; then
        echo "$dataset already exists in HDFS; skipping."
        continue
    fi

    archive="$download_dir/$filename.gz"
    if [ ! -f "$archive" ]; then
        echo "Downloading $dataset from IMDb..."
        url="https://datasets.imdbws.com/$filename.gz"
        if command -v curl >/dev/null 2>&1; then
            curl --fail --location --retry 3 --output "$archive.part" "$url"
        else
            wget --tries=3 -O "$archive.part" "$url"
        fi
        gzip -t "$archive.part"
        mv "$archive.part" "$archive"
    fi

    echo "Uploading $dataset to $target..."
    gzip -dc "$archive" > "$download_dir/$filename.part"
    hdfs dfs -mkdir -p "$target"
    hdfs dfs -put -f "$download_dir/$filename.part" "$target/.$filename.uploading"
    hdfs dfs -mv "$target/.$filename.uploading" "$target/$filename"
    rm -f "$download_dir/$filename.part"
done

echo "IMDb data is ready. Run: hive -f /app/data/02_hive/my_solution.sql"
