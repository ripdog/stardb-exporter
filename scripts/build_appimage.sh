#!/usr/bin/env bash
set -euo pipefail

# Build a self contained AppImage for stardb-exporter.
# Designed to work locally and in CI. Requires: curl, jq, patchelf, libpcap-dev.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${TARGET_DIR:-"$ROOT/target"}"
APPDIR="$TARGET_DIR/AppDir"
BIN_NAME="stardb-exporter"
DESKTOP_ID="stardb-exporter"
ICON_SRC="${ICON_SRC:-"$ROOT/icons/icon.png"}"

command -v curl >/dev/null || { echo "curl is required"; exit 1; }
command -v jq >/dev/null || { echo "jq is required"; exit 1; }

# Prefer an existing cargo; otherwise fall back to rustup without changing the user's default toolchain.
if command -v cargo >/dev/null 2>&1; then
    CARGO_BIN=(cargo)
elif command -v rustup >/dev/null 2>&1; then
    TOOLCHAIN="${RUSTUP_TOOLCHAIN:-stable}"
    CARGO_BIN=(rustup run "$TOOLCHAIN" cargo)
else
    echo "cargo or rustup is required" >&2
    exit 1
fi

# If the cargo shim has no default toolchain, fall back to rustup run stable.
if ! "${CARGO_BIN[@]}" --version >/dev/null 2>&1; then
    if command -v rustup >/dev/null 2>&1; then
        TOOLCHAIN="${RUSTUP_TOOLCHAIN:-stable}"
        CARGO_BIN=(rustup run "$TOOLCHAIN" cargo)
    fi
fi

# Final sanity check.
if ! "${CARGO_BIN[@]}" --version >/dev/null 2>&1; then
    echo "cargo is not usable; please install Rust (e.g., 'rustup default stable')" >&2
    exit 1
fi

# Determine version for the output name.
APP_VERSION="${APP_VERSION:-$("${CARGO_BIN[@]}" metadata --format-version 1 --no-deps | jq -r '.packages[] | select(.name=="stardb-exporter") | .version')}"
APPIMAGE_NAME="${APPIMAGE_NAME:-"${BIN_NAME}-${APP_VERSION}-x86_64.AppImage"}"

# Download helper tools if missing.
LINUXDEPLOY="${LINUXDEPLOY:-"$TARGET_DIR/linuxdeploy-x86_64.AppImage"}"
APPIMAGETOOL="${APPIMAGETOOL:-"$TARGET_DIR/appimagetool-x86_64.AppImage"}"

download_if_missing() {
    local dest="$1"
    local url="$2"
    if [[ ! -x "$dest" ]]; then
        echo "Downloading $(basename "$dest")..."
        mkdir -p "$(dirname "$dest")"
        curl -L "$url" -o "$dest"
        chmod +x "$dest"
    fi
}

download_if_missing "$LINUXDEPLOY" "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
download_if_missing "$APPIMAGETOOL" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"

# Build the binary unless explicitly skipped.
if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
    "${CARGO_BIN[@]}" build --release
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/512x512/apps"

cp "$ROOT/target/release/$BIN_NAME" "$APPDIR/usr/bin/"
cp "$ICON_SRC" "$APPDIR/usr/share/icons/hicolor/512x512/apps/${DESKTOP_ID}.png"

cat > "$APPDIR/usr/share/applications/${DESKTOP_ID}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Stardb Exporter
Exec=${BIN_NAME}
Icon=${DESKTOP_ID}
Categories=Utility;
Terminal=false
EOF

# Convenience symlinks expected by linuxdeploy.
ln -sf "usr/share/applications/${DESKTOP_ID}.desktop" "$APPDIR/${DESKTOP_ID}.desktop"
ln -sf "usr/share/icons/hicolor/512x512/apps/${DESKTOP_ID}.png" "$APPDIR/${DESKTOP_ID}.png"

export APPIMAGETOOL
export APPIMAGE_EXTRACT_AND_RUN="${APPIMAGE_EXTRACT_AND_RUN:-1}"
# Avoid strip failures on modern distros (RELR); linuxdeploy respects NO_STRIP env.
export NO_STRIP=1

# Run linuxdeploy from target so the resulting AppImage lands there.
pushd "$TARGET_DIR" >/dev/null
"$LINUXDEPLOY" \
    --appdir "$APPDIR" \
    --executable "$APPDIR/usr/bin/$BIN_NAME" \
    --desktop-file "$APPDIR/usr/share/applications/${DESKTOP_ID}.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/512x512/apps/${DESKTOP_ID}.png" \
    --output appimage

PRODUCED_APPIMAGE="$(ls -t *.AppImage | head -n1)"
if [[ -n "$PRODUCED_APPIMAGE" && "$PRODUCED_APPIMAGE" != "$APPIMAGE_NAME" ]]; then
    mv "$PRODUCED_APPIMAGE" "$APPIMAGE_NAME"
    PRODUCED_APPIMAGE="$APPIMAGE_NAME"
fi
popd >/dev/null

echo "AppImage created at $TARGET_DIR/$PRODUCED_APPIMAGE"
