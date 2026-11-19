#!/usr/bin/env bash
# ==============================================================================
# install-openbot.sh - Instalador de OpenBot (Nightly Labs)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

TARGET_DIR="${HOME}/.local/share/openbot"
TARGET_APPIMAGE="${TARGET_DIR}/OpenBot.AppImage"
ICON_TARGET_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"
ICON_FILE="${ICON_TARGET_DIR}/openbot.png"
DESKTOP_FILE="${HOME}/.local/share/applications/openbot.desktop"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "${TARGET_DIR}" "${ICON_TARGET_DIR}" "${HOME}/.local/share/applications" "${BIN_DIR}"

echo "=== OpenBot ==="

case "${ARCH}" in
    x86_64) ASSET_SUFFIX="x86_64.AppImage" ;;
    aarch64|arm64) ASSET_SUFFIX="arm64.AppImage" ;;
    *)
        echo "  [i] Arquitectura ${ARCH} no soportada para OpenBot AppImage."
        exit 0
        ;;
esac

if [ -f "${TARGET_APPIMAGE}" ] && [ -s "${TARGET_APPIMAGE}" ]; then
    echo "  [✓] OpenBot ya está instalado."
elif [ "${LINUX_SETUP_SKIP_LARGE_APPIMAGES:-0}" = "1" ]; then
    echo "  [i] OpenBot omitido por LINUX_SETUP_SKIP_LARGE_APPIMAGES=1."
else
    FOUND_DOWNLOAD="$(find "${HOME}/Downloads" -maxdepth 1 -iname "*openbot*${ASSET_SUFFIX}*" 2>/dev/null | head -n1 || true)"
    if [ -n "${FOUND_DOWNLOAD}" ] && [ -f "${FOUND_DOWNLOAD}" ]; then
        cp -f "${FOUND_DOWNLOAD}" "${TARGET_APPIMAGE}"
        chmod +x "${TARGET_APPIMAGE}"
        echo "  [✓] OpenBot copiado desde Descargas."
    else
        LATEST_URL="$(safe_fetch "https://api.github.com/repos/nightly-labs/openbot/releases/latest" 20 \
            | grep "browser_download_url" \
            | grep -E "OpenBot-.*-${ASSET_SUFFIX}" \
            | cut -d '"' -f 4 \
            | head -n1 || true)"
        if [ -n "${LATEST_URL}" ]; then
            echo "  [+] Descargando OpenBot..."
            if safe_download "${LATEST_URL}" "${TARGET_APPIMAGE}" 300; then
                chmod +x "${TARGET_APPIMAGE}"
                echo "  [✓] OpenBot instalado."
            else
                echo "  [!] No se pudo descargar OpenBot."
            fi
        else
            echo "  [i] No se encontró release AppImage de OpenBot en GitHub."
        fi
    fi
fi

if [ ! -f "${ICON_FILE}" ]; then
    safe_download "https://openbot.run/favicon.ico" "${ICON_FILE}" 15 2>/dev/null || true
fi

cat << 'EOF_CLI' > "${BIN_DIR}/openbot"
#!/usr/bin/env bash
TARGET="${HOME}/.local/share/openbot/OpenBot.AppImage"
if [ ! -x "${TARGET}" ]; then
    echo "[!] OpenBot no está instalado en ${TARGET}."
    exit 1
fi
exec "${TARGET}" "$@"
EOF_CLI
chmod +x "${BIN_DIR}/openbot"

cat << EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Type=Application
Name=OpenBot
Comment=Local-first AI Teammates Desktop Workspace
Exec=${BIN_DIR}/openbot %U
Icon=${ICON_FILE}
Terminal=false
Categories=Development;Utility;
EOF
chmod +x "${DESKTOP_FILE}"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
