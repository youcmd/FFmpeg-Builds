#!/bin/bash
set -e

if [[ $# -lt 2 ]]; then
    echo "Missing arguments"
    exit -1
fi

RELEASE_DIR="$(realpath "$1")"
shift
mkdir -p "$RELEASE_DIR"

while [[ $# -gt 0 ]]; do
    INPUT="$1"
    shift

    (
        set -e

        if [[ $INPUT == *.zip ]]; then
            OUTEXT="zip"
        elif [[ $INPUT == *.7z ]]; then
            OUTEXT="7z"
        elif [[ $INPUT == *.tar.xz ]]; then
            OUTEXT="tar.xz"
        else
            echo "Unknown input file type: $INPUT"
            exit 1
        fi

        if [[ $OUTEXT == 7z ]]; then
            INAME="$(7z l -slt -p"$ASS" "$INPUT" | awk -F' = ' '/^----------$/ {listing=1; next} listing && $1 == "Path" {split($2, a, "/"); print a[1]; exit}')"
        else
            INAME="$(bsdtar -tf "$INPUT" | head -1 | cut -d/ -f1)"
        fi

        TAGNAME="$(cut -d- -f2 <<<"$INAME")"

        if [[ $TAGNAME == N ]]; then
            TAGNAME="master"
        elif [[ $TAGNAME == n* ]]; then
            TAGNAME="$(sed -re 's/([0-9]+\.[0-9]+).*/\1/' <<<"$TAGNAME")"
        fi

        if [[ "$INAME" =~ -[0-9]+-g ]]; then
            ONAME="ffmpeg-$TAGNAME-latest-$(cut -d- -f5- <<<"$INAME")"
        else
            ONAME="ffmpeg-$TAGNAME-latest-$(cut -d- -f3- <<<"$INAME")"
        fi

        OUTPUT="$RELEASE_DIR/$ONAME.$OUTEXT"

        if [[ $OUTEXT == tar.xz ]]; then
            bsdtar -cf "$OUTPUT" --format gnutar --xz --options xz:threads=0 -s "|^$INAME/|$ONAME/|" "@$INPUT"
        else
            cp "$INPUT" "$OUTPUT"

            if [[ $OUTEXT == 7z ]]; then
                7z rn -bso0 -bsp0 -p"$ASS" "$OUTPUT" "$INAME" "$ONAME"
                ROOT_NAME="$(7z l -slt -p"$ASS" "$OUTPUT" | awk -F' = ' '/^----------$/ {listing=1; next} listing && $1 == "Path" {split($2, a, "/"); print a[1]; exit}')"
            else
                7z rn -bso0 -bsp0 "$OUTPUT" "$INAME" "$ONAME"
                ROOT_NAME="$(bsdtar -tf "$OUTPUT" | head -1 | cut -d/ -f1)"
            fi

            [[ "$ROOT_NAME" == "$ONAME" ]]
        fi
    ) &

    while [[ $(jobs | wc -l) -gt 3 ]]; do
        wait %1
    done
done

while [[ $(jobs | wc -l) -gt 0 ]]; do
    wait %1
done
