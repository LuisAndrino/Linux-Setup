#!/usr/bin/env bash
# ==============================================================================
# install-antigravity.sh - Instalador multi-distro de Google Antigravity App GUI
# ==============================================================================
# Ubuntu/Debian: instala paquete oficial .deb (con fallback a AppImage)
# Fedora/Arch/openSUSE/Inmutables: AppImage oficial + ícono + .desktop GUI
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Google Antigravity App (GUI) ==="

if command -v antigravity >/dev/null 2>&1 || [ -x "${HOME}/.local/share/Antigravity/Antigravity.AppImage" ]; then
    echo "  [✓] Google Antigravity ya está instalado."
    exit 0
fi

if [ "${ARCH}" != "x86_64" ]; then
    echo "  [i] Google Antigravity solo tiene compilación x86_64 (actual: ${ARCH}). Omitiendo."
    exit 0
fi

if [ "${LINUX_SETUP_SKIP_LARGE_APPIMAGES:-0}" = "1" ]; then
    echo "  [i] Antigravity omitido por LINUX_SETUP_SKIP_LARGE_APPIMAGES=1."
    exit 0
fi

MANIFEST_URL="https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/manifest/latest-x64-linux.yml"
MANIFEST_DATA="$(safe_fetch "${MANIFEST_URL}" 20 || true)"
DEB_URL="$(printf '%s\n' "${MANIFEST_DATA}" | grep -Eo 'https://[^[:space:]]+Antigravity\.deb' | head -n1 || true)"
APPIMAGE_URL="$(printf '%s\n' "${MANIFEST_DATA}" | grep -Eo 'https://[^[:space:]]+Antigravity\.AppImage' | head -n1 || true)"
APPIMAGE_URL="${APPIMAGE_URL:-https://storage.googleapis.com/antigravity-public/antigravity-hub/2.34.0-5887025308631040/linux-x64/Antigravity.AppImage}"

# 1. En Debian/Ubuntu intentar primero paquete oficial .deb (integración GUI completa)
if [ "${PKG_MGR}" = "apt" ] && [ -n "${DEB_URL}" ]; then
    TMP_DEB="/tmp/Antigravity-$$.deb"
    echo "  [+] Descargando paquete oficial Antigravity (.deb)..."
    if safe_download "${DEB_URL}" "${TMP_DEB}" 300; then
        if run_root env DEBIAN_FRONTEND=noninteractive apt-get "${APT_OPTS[@]}" install -qq "${TMP_DEB}"; then
            rm -f "${TMP_DEB}"
            echo "  [✓] Google Antigravity App GUI instalada vía paquete .deb oficial."
            exit 0
        fi
        rm -f "${TMP_DEB}"
    fi
fi

# 2. AppImage oficial multi-distro (Fedora, Arch, openSUSE, inmutables o fallback)
INSTALL_DIR="${HOME}/.local/share/Antigravity"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"
ICON_FILE="${ICON_DIR}/antigravity.png"
mkdir -p "${INSTALL_DIR}" "${BIN_DIR}" "${DESKTOP_DIR}" "${ICON_DIR}"

TARGET_FILE="${INSTALL_DIR}/Antigravity.AppImage"
echo "  [+] Descargando Google Antigravity AppImage..."
if safe_download "${APPIMAGE_URL}" "${TARGET_FILE}" 300; then
    chmod +x "${TARGET_FILE}"
    ln -sf "${TARGET_FILE}" "${BIN_DIR}/antigravity"

    if [ ! -f "${ICON_FILE}" ]; then
        TMP_EX="/tmp/ag-icon-$$"
        mkdir -p "${TMP_EX}"
        (
            cd "${TMP_EX}"
            timeout 20 "${TARGET_FILE}" --appimage-extract "*.png" >/dev/null 2>&1 || true
            FOUND_ICON="$(find "${TMP_EX}" -iname "*antigravity*.png" -o -iname "*.DirIcon" 2>/dev/null | head -n1 || true)"
            [ -n "${FOUND_ICON}" ] && [ -f "${FOUND_ICON}" ] && cp -f "${FOUND_ICON}" "${ICON_FILE}"
        ) || true
        rm -rf "${TMP_EX}"
    fi

    ICON_VAL="antigravity"
    [ -f "${ICON_FILE}" ] && ICON_VAL="${ICON_FILE}"

    cat << EOF > "${DESKTOP_DIR}/antigravity.desktop"
[Desktop Entry]
Name=Antigravity
Comment=Google Antigravity AI Agent Platform
GenericName=AI Agent Platform
Exec=${TARGET_FILE} %F
Icon=${ICON_VAL}
Type=Application
StartupNotify=false
StartupWMClass=Antigravity
Categories=Development;Utility;
Keywords=antigravity;agent;ai;
EOF

    cat << EOF > "${DESKTOP_DIR}/antigravity-url-handler.desktop"
[Desktop Entry]
Name=Antigravity - URL Handler
Comment=Google Antigravity URL Handler
Exec=${TARGET_FILE} "%U"
Icon=${ICON_VAL}
Type=Application
NoDisplay=true
Terminal=false
StartupNotify=true
StartupWMClass=Antigravity
Categories=Utility;Development;
MimeType=x-scheme-handler/antigravity;
EOF

    chmod +x "${DESKTOP_DIR}/antigravity.desktop" "${DESKTOP_DIR}/antigravity-url-handler.desktop"
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
    echo "  [✓] Google Antigravity App GUI instalada en ${TARGET_FILE}."
else
    echo "  [!] No se pudo descargar Google Antigravity."
fi
