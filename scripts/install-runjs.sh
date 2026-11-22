#!/usr/bin/env bash
# ==============================================================================
# install-runjs.sh - Instalador multi-distro de RunJS (AppImage oficial + GUI)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

TARGET_DIR="${HOME}/.local/share/runjs"
TARGET_APPIMAGE="${TARGET_DIR}/RunJS.AppImage"
ICON_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"
ICON_FILE="${ICON_DIR}/runjs.png"
DESKTOP_FILE="${HOME}/.local/share/applications/runjs.desktop"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "${TARGET_DIR}" "${ICON_DIR}" "${HOME}/.local/share/applications" "${BIN_DIR}"

echo "=== RunJS ==="

if [ -x "${TARGET_APPIMAGE}" ] && [ -s "${TARGET_APPIMAGE}" ]; then
    echo "  [✓] RunJS ya está instalado en ${TARGET_APPIMAGE}."
elif [ "${LINUX_SETUP_SKIP_LARGE_APPIMAGES:-0}" = "1" ]; then
    echo "  [i] RunJS omitido por LINUX_SETUP_SKIP_LARGE_APPIMAGES=1."
else
    case "${ARCH}" in
        x86_64|amd64)
            REGEX='RunJS-[0-9]+\.[0-9]+\.[0-9]+\.AppImage"'
            FALLBACK_URL="https://github.com/lukehaas/RunJS/releases/download/v4.1.0/RunJS-4.1.0.AppImage"
            ;;
        aarch64|arm64)
            REGEX='RunJS-[0-9]+\.[0-9]+\.[0-9]+-arm64\.AppImage"'
            FALLBACK_URL="https://github.com/lukehaas/RunJS/releases/download/v4.1.0/RunJS-4.1.0-arm64.AppImage"
            ;;
        *)
            echo "  [i] Arquitectura ${ARCH} no soportada para RunJS."
            exit 0
            ;;
    esac

    LATEST_URL="$(safe_fetch "https://api.github.com/repos/lukehaas/RunJS/releases/latest" 20 \
        | grep "browser_download_url" \
        | grep -E "${REGEX}" \
        | cut -d '"' -f 4 \
        | head -n1 || true)"
    LATEST_URL="${LATEST_URL:-$FALLBACK_URL}"

    echo "  [+] Descargando RunJS (${LATEST_URL##*/})..."
    if safe_download "${LATEST_URL}" "${TARGET_APPIMAGE}" 300; then
        chmod +x "${TARGET_APPIMAGE}"
        echo "  [✓] RunJS descargado en ${TARGET_APPIMAGE}."
    else
        echo "  [!] No se pudo descargar RunJS."
    fi
fi

if [ -x "${TARGET_APPIMAGE}" ]; then
    if [ ! -f "${ICON_FILE}" ]; then
        TMP_EX="/tmp/runjs-icon-$$"
        mkdir -p "${TMP_EX}"
        (
            cd "${TMP_EX}"
            timeout 20 "${TARGET_APPIMAGE}" --appimage-extract "*.png" >/dev/null 2>&1 || true
            FOUND_ICON="$(find "${TMP_EX}" -iname "*runjs*.png" -o -iname "*.DirIcon" 2>/dev/null | head -n1 || true)"
            [ -n "${FOUND_ICON}" ] && [ -f "${FOUND_ICON}" ] && cp -f "${FOUND_ICON}" "${ICON_FILE}"
        ) || true
        rm -rf "${TMP_EX}"
    fi

    cat << 'EOF_CLI' > "${BIN_DIR}/runjs"
#!/usr/bin/env bash
exec "${HOME}/.local/share/runjs/RunJS.AppImage" "$@"
EOF_CLI
    chmod +x "${BIN_DIR}/runjs"

    cat << EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Type=Application
Name=RunJS
Comment=JavaScript and TypeScript playground for desktop
Exec=${BIN_DIR}/runjs %U
Icon=${ICON_FILE}
Terminal=false
StartupWMClass=RunJS
Categories=Development;IDE;
EOF
    chmod +x "${DESKTOP_FILE}"
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
    echo "  [✓] RunJS configurado (comando 'runjs' y acceso GUI)."
fi
