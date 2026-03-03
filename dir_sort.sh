#!/bin/bash

# check arguments
if [ $# -ne 2 ]; then
    echo "Використання: $0 <шлях_до_директорії> <ext|size>"
    exit 1
fi

DIR="$1"
PARAM="$2"

# check dir exist
if [ ! -d "$DIR" ]; then
    echo "Помилка: директорія '$DIR' не існує"
    exit 1
fi

if [ "$PARAM" == "size" ]; then
    echo "Sorting directory contents by file size:"
    du -sh "$DIR"/* 2>/dev/null | sort -h | awk '{print $1, $2}' | while read size path; do
        echo "$size $(basename $path)"
    done

elif [ "$PARAM" == "ext" ]; then
    echo "Sorting directory contents by extension:"
    ls "$DIR" | sort -t'.' -k2,2 | while read file; do
        echo "$file"
    done

else
    echo "Помилка: другий параметр має бути 'ext' або 'size'"
    exit 1
fi
