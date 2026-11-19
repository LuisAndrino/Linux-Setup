#!/usr/bin/env bash
# ==============================================================================
# install-antigravity.sh - Instalador universal de Google Antigravity
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Google Antigravity ==="

if command -v antigravity >/dev/null 2>&1 || [ -x "${HOME}/.local/share/Antigravity/Antigravity.AppImage" ]; then
    echo "  [✓] Antigravity ya está instalado."
    exit 0
fi

if [ "${ARCH}" != "x86_64" ]; then
    echo "  [i] Antigravity AppImage es x86_64 (actual: ${ARCH}). Omitiendo."
    exit 0
fi

if [ "${LINUX_SETUP_SKIP_LARGE_APPIMAGES:-0}" = "1" ]; then
    echo "  [i] Antigravity omitido por LINUX_SETUP_SKIP_LARGE_APPIMAGES=1."
    exit 0
fi

INSTALL_DIR="${HOME}/.local/share/Antigravity"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
mkdir -p "${INSTALL_DIR}" "${BIN_DIR}" "${DESKTOP_DIR}"

MANIFEST_URL="https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/manifest/latest-x64-linux.yml"
APPIMAGE_URL="$(safe_fetch "${MANIFEST_URL}" 20 | grep -Eo 'https://[^[:space:]]+Antigravity\.AppImage' | head -n1 || true)"

if [ -z "${APPIMAGE_URL}" ]; then
    APPIMAGE_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.33.0-4731201358004224/linux-x64/Antigravity.AppImage"
fi

TARGET_FILE="${INSTALL_DIR}/Antigravity.AppImage"
echo "  [+] Descargando Antigravity..."
if safe_download "${APPIMAGE_URL}" "${TARGET_FILE}" 300; then
    chmod +x "${TARGET_FILE}"
    ln -sf "${TARGET_FILE}" "${BIN_DIR}/antigravity"

    cat << EOF > "${DESKTOP_DIR}/antigravity.desktop"
[Desktop Entry]
Name=Antigravity
Comment=Agent orchestration platform
GenericName=AI Agent Platform
Exec=${TARGET_FILE} %F
Icon=antigravity
Type=Application
StartupNotify=false
StartupWMClass=Antigravity
Categories=Development;Utility;
Keywords=antigravity;agent;ai;
EOF

    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
    echo "  [✓] Google Antigravity instalado en ${TARGET_FILE}."
else
    echo "  [!] No se pudo descargar Google Antigravity."
fi
