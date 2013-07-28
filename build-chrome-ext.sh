#!/bin/bash -e

# Purpose: Pack a Chrome extension directory into crx format
# Source:  http://developer.chrome.com/extensions/crx.html

if test $# -ne 4; then
	echo "Usage: build-chrome-ext.sh EXT_PREFIX CERT_DIR TEMP_DIR BUILD_SRC"
	exit 1
fi

EXT_PREFIX=$1
CERT_DIR=$2
TEMP_DIR=$3
BUILD_SRC=$4

zip="$TEMP_DIR/chrome.zip"
pub="$TEMP_DIR/chrome.pub"
sig="$TEMP_DIR/chrome.sig"

mkdir -p "$TEMP_DIR"

# Change to temp/extension_name.safariextension
( cd "$TEMP_DIR/$BUILD_SRC" &&
	zip -qr --exclude=*.Info.plist* --exclude=*.coffee -9 -X "$zip" . )

openssl sha1 -sha1 -binary -sign "$CERT_DIR/chrome.pem" < "$zip" > "$sig"
openssl rsa -pubout -outform DER < "$CERT_DIR/chrome.pem" > "$pub" 2>/dev/null

byte_swap () {
	# Take "abcdefgh" and return it as "ghefcdab"
	echo "${1:6:2}${1:4:2}${1:2:2}${1:0:2}"
}

crmagic_hex="4372 3234" # Cr24
version_hex="0200 0000" # 2

# Take the filesize, turn it to hex
pub_len_hex=$(byte_swap $(printf '%08x\n' $(ls -l "$pub" | awk '{print $5}')))
sig_len_hex=$(byte_swap $(printf '%08x\n' $(ls -l "$sig" | awk '{print $5}')))

(
	echo "$crmagic_hex $version_hex $pub_len_hex $sig_len_hex" | xxd -r -p
	cat "$pub" "$sig" "$zip"
) > "$EXT_PREFIX.crx"


exit