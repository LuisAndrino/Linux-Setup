#!/usr/bin/env bash
# ==============================================================================
# install-streaming-launcher.sh - Instalador de Streaming Service Launcher
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Streaming Service Launcher ==="

if [ "${ARCH}" != "x86_64" ]; then
    echo "  [i] StreamingServiceLauncher es x86_64 (actual: ${ARCH})."
    exit 0
fi

APP_DIR="${HOME}/Applications"
TARGET_APPIMAGE="${APP_DIR}/StreamingServiceLauncher.AppImage"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_FILE="${HOME}/.local/share/applications/streaming-service-launcher.desktop"
mkdir -p "${APP_DIR}" "${BIN_DIR}" "${HOME}/.local/share/applications"

if [ -f "${TARGET_APPIMAGE}" ] && [ -s "${TARGET_APPIMAGE}" ]; then
    echo "  [✓] StreamingServiceLauncher ya está instalado."
elif [ "${LINUX_SETUP_SKIP_LARGE_APPIMAGES:-0}" = "1" ]; then
    echo "  [i] StreamingServiceLauncher omitido por LINUX_SETUP_SKIP_LARGE_APPIMAGES=1."
else
    LATEST_URL="$(safe_fetch "https://api.github.com/repos/aarron-lee/StreamingServiceLauncher/releases/latest" 20 \
        | grep "browser_download_url" \
        | grep -E "StreamingServiceLauncher_.*_linux\.AppImage" \
        | cut -d '"' -f 4 \
        | head -n1 || true)"
    if [ -n "${LATEST_URL}" ]; then
        echo "  [+] Descargando StreamingServiceLauncher..."
        if safe_download "${LATEST_URL}" "${TARGET_APPIMAGE}" 240; then
            chmod +x "${TARGET_APPIMAGE}"
            echo "  [✓] StreamingServiceLauncher instalado."
        else
            echo "  [!] No se pudo descargar StreamingServiceLauncher."
        fi
    fi
fi

if [ -f "${TARGET_APPIMAGE}" ]; then
    cat << EOF_CLI > "${BIN_DIR}/streaming-service-launcher"
#!/usr/bin/env bash
exec "${TARGET_APPIMAGE}" --appname="\${1:-}" --no-sandbox
EOF_CLI
    chmod +x "${BIN_DIR}/streaming-service-launcher"

    cat << EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Type=Application
Name=Streaming Services
Comment=Launch web streaming services (Netflix, Disney+, YouTube)
Exec=${BIN_DIR}/streaming-service-launcher
Icon=video-display
Terminal=false
Categories=AudioVideo;Video;Network;
EOF
    chmod +x "${DESKTOP_FILE}"
fi
