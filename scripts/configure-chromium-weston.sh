#!/bin/sh
set -eu

ROOT=/opt/floor-chromium
CONF=/etc/xdg/weston/weston.ini
LAUNCHER=/usr/local/bin/floor-chromium
ICON="$ROOT/usr/share/icons/hicolor/32x32/apps/chromium.png"

SOURCE="${1:?Usage: configure-chromium-weston.sh <launcher-file>}"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run as root"
    exit 1
fi

test -x "$ROOT/usr/lib/chromium/chromium-bin"
test -u "$ROOT/usr/lib/chromium/chrome-sandbox"
test -f "$ICON"
test -f "$CONF"
test -f "$SOURCE"

grep -q '^ROOT=/opt/floor-chromium$' "$SOURCE"

echo "=== BACKING UP CONFIGURATION ==="

[ -e "$CONF.before_floor_chromium" ] ||
    cp -a "$CONF" "$CONF.before_floor_chromium"

if [ -f "$LAUNCHER" ]; then
    [ -e "$LAUNCHER.before_floor_chromium" ] ||
        cp -a "$LAUNCHER" "$LAUNCHER.before_floor_chromium"
fi

echo "=== INSTALLING CHROMIUM LAUNCHER ==="

cp "$SOURCE" "$LAUNCHER"
chmod 755 "$LAUNCHER"
sh -n "$LAUNCHER"

echo "=== CONFIGURING WESTON ICON ==="

if grep -q '^path=/usr/local/bin/floor-chromium$' "$CONF"; then
    sed -i \
      "s|/opt/floor-chromium-sandbox-test/usr/share/icons/hicolor/32x32/apps/chromium.png|$ICON|g" \
      "$CONF"
else
    printf '\n[launcher]\nicon=%s\ndisplayname=Chromium\npath=%s\n' \
      "$ICON" "$LAUNCHER" >> "$CONF"
fi

echo "=== VERIFICATION ==="

grep '^ROOT=' "$LAUNCHER"
grep -F "icon=$ICON" "$CONF"
grep -F "path=$LAUNCHER" "$CONF"

echo "SUCCESS: Weston Chromium launcher configured."
echo "Restart Weston or reboot to load the panel icon."
