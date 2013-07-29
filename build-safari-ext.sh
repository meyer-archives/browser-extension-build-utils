#!/bin/bash -e

# Purpose: Pack a Safari extension directory into safariext format
# Source:  http://blog.streak.com/2013/01/how-to-build-safari-extension.html

if test $# -ne 4; then
	echo "Usage: build-safari-ext.sh EXT_PREFIX CERT_DIR TEMP_DIR BUILD_SRC"
	exit 1
fi

EXT_PREFIX=$1
CERT_DIR=$2
TEMP_DIR=$3
BUILD_SRC=$4

zip="$TEMP_DIR/safari.zip"
digest="$TEMP_DIR/safari.digest"
sig="$TEMP_DIR/safari.sig"

mkdir -p "$TEMP_DIR"

# Change to build/
( cd "$TEMP_DIR" &&
	xar -czf "$zip" --distribution "./$BUILD_SRC" )

xar --sign -f "$zip" \
	--digestinfo-to-sign "$digest" \
	--sig-size 256 \
	--exclude *manifest.json* \
	--exclude *.coffee \
	--cert-loc "$CERT_DIR/cert.der" \
	--cert-loc "$CERT_DIR/cert01" \
	--cert-loc "$CERT_DIR/cert02"

openssl rsautl -sign \
	-inkey "$CERT_DIR/safari.pem" \
	-in "$digest" \
	-out "$sig"

xar --inject-sig "$sig" \
	-f "$zip"

cp "$zip" "$EXT_PREFIX.safariextz"

exit