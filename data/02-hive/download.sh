#!/bin/bash
set -Eeuo pipefail
cache_dir="${1:?Usage: download.sh CACHE_DIRECTORY}"
mkdir -p "$cache_dir"
for dataset in title.basics title.ratings name.basics; do
    archive="$cache_dir/$dataset.tsv.gz"
    if [ ! -s "$archive" ]; then
        curl --fail --location --retry 5 --retry-delay 5 \
            "https://datasets.imdbws.com/$dataset.tsv.gz" -o "$archive.part"
        gzip -t "$archive.part"
        mv "$archive.part" "$archive"
    fi
done
