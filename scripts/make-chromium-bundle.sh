#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:?Usage: $0 <yocto-build-directory>}"
BUILD_DIR="$(realpath "$BUILD_DIR")"

RPM_BASE="$BUILD_DIR/deploy-ampliphy-vendor-xwayland/rpm"
OUT="$PWD/releases/pollux-chromium-117-gpu.tar.gz"

for tool in rpm2cpio cpio tar sha256sum; do
    command -v "$tool" >/dev/null || {
        echo "Missing required tool: $tool"
        exit 1
    }
done

test -d "$RPM_BASE" || {
    echo "RPM directory not found: $RPM_BASE"
    exit 1
}

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

echo "=== COLLECTING CHROMIUM PACKAGES ==="

for pkg in chromium-ozone-wayland libcxx nss nspr libxslt; do
    mapfile -d '' RPM_FILES < <(
        find "$RPM_BASE" -type f \
          -name "$pkg-[0-9]*.rpm" -print0
    )

    if [ "${#RPM_FILES[@]}" -ne 1 ]; then
        echo "Expected one RPM for $pkg, found ${#RPM_FILES[@]}"
        exit 1
    fi

    RPM="${RPM_FILES[0]}"

    echo "Extracting $(basename "$RPM")"

    rpm2cpio "$RPM" | (
        cd "$STAGE"
        cpio -idm --quiet
    )
done

echo "=== VERIFYING CONTENTS ==="

for file in \
    usr/lib/chromium/chromium-bin \
    usr/lib/chromium/chrome-sandbox \
    usr/lib/libc++.so.1 \
    usr/lib/libnss3.so \
    usr/lib/libnspr4.so \
    usr/lib/libxslt.so.1
do
    test -e "$STAGE/$file" || {
        echo "Missing: $file"
        exit 1
    }
done

echo "=== CREATING DISTRIBUTION ==="

mkdir -p "$(dirname "$OUT")"
tar -C "$STAGE" -czf "$OUT" usr

(
    cd "$(dirname "$OUT")"
    sha256sum "$(basename "$OUT")" > "$(basename "$OUT").sha256"
)

echo "=== COMPLETE ==="
ls -lh "$OUT" "$OUT.sha256"
echo "Bundle created successfully."
