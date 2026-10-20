#!/bin/bash
set -Eeuo pipefail
cache_dir="${1:?Usage: download.sh CACHE_DIRECTORY}"
mkdir -p "$cache_dir"
if [ ! -s "$cache_dir/Faust_1.txt" ]; then
    if [ ! -d "$cache_dir/course/.git" ]; then
        git clone --depth 1 --filter=blob:none --no-checkout \
            https://github.com/marcelmittelstaedt/BigData.git "$cache_dir/course"
    fi
    sample="$(git -C "$cache_dir/course" ls-tree -r --name-only HEAD | \
        awk '/\/Faust_1.txt$/ && !found {sample=$0; found=1} END {print sample}')"
    test -n "$sample"
    git -C "$cache_dir/course" show "HEAD:$sample" > "$cache_dir/Faust_1.txt.part"
    test -s "$cache_dir/Faust_1.txt.part"
    mv "$cache_dir/Faust_1.txt.part" "$cache_dir/Faust_1.txt"
    git -C "$cache_dir/course" rev-parse HEAD > "$cache_dir/course-commit.txt"
fi
