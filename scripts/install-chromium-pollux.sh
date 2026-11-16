#!/bin/sh
set -eu

BUNDLE="${1:?Usage: install-chromium-pollux.sh <bundle>}"
ROOT=/opt/floor-chromium

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run as root"
    exit 1
fi

test -f "$BUNDLE" || {
    echo "ERROR: Bundle not found: $BUNDLE"
    exit 1
}

if [ -e "$ROOT" ]; then
    echo "ERROR: $ROOT already exists"
    exit 1
fi

STAGE="${ROOT}.staging.$$"
mkdir -p "$STAGE"
trap 'rm -rf "$STAGE"' EXIT HUP INT TERM

echo "=== EXTRACTING CHROMIUM ==="
tar -xzf "$BUNDLE" -C "$STAGE"

echo "=== CHECKING REQUIRED FILES ==="

for file in \
    usr/lib/chromium/chromium-bin \
    usr/lib/chromium/chrome-sandbox \
    usr/lib/libc++.so.1 \
    usr/lib/libnss3.so \
    usr/lib/libnspr4.so \
    usr/lib/libxslt.so.1
do
    test -e "$STAGE/$file" || {
        echo "ERROR: Missing $file"
        exit 1
    }
done

echo "=== CONFIGURING SANDBOX ==="
chown -R root:root "$STAGE"

SANDBOX="$STAGE/usr/lib/chromium/chrome-sandbox"
chmod 4755 "$SANDBOX"

echo "=== VERIFYING SHARED LIBRARIES ==="
if ! OUTPUT=$(LD_LIBRARY_PATH="$STAGE/usr/lib" \
    /lib/ld-linux-aarch64.so.1 --list \
    "$STAGE/usr/lib/chromium/chromium-bin" 2>&1); then
    echo "$OUTPUT"
    exit 1
fi

if printf '%s\n' "$OUTPUT" | grep -q 'not found'; then
    echo "$OUTPUT"
    exit 1
fi

echo "=== FINALIZING INSTALLATION ==="
mv "$STAGE" "$ROOT"
trap - EXIT HUP INT TERM

ls -l "$ROOT/usr/lib/chromium/chrome-sandbox"

echo "SUCCESS: Chromium installed at $ROOT"
echo "Existing Chromium launcher was not changed."
