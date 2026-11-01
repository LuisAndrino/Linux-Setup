#!/usr/bin/env bash
# ==============================================================================
# install-streaming-launcher.sh - Instalador de Streaming Service Launcher
# ==============================================================================
# Lanzador optimizado para servicios de streaming (Netflix, Disney+, YouTube, etc.)
# integrados en Steam Gaming Mode y modo Escritorio.
# Repositorio: https://github.com/aarron-lee/StreamingServiceLauncher
# ==============================================================================
set -euo pipefail

APP_DIR="${HOME}/Applications"
TARGET_APPIMAGE="${APP_DIR}/StreamingServiceLauncher.AppImage"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_FILE="${HOME}/.local/share/applications/streaming-service-launcher.desktop"

mkdir -p "${APP_DIR}" "${BIN_DIR}" "${HOME}/.local/share/applications"

echo "=========================================================="
echo "       Instalación de Streaming Service Launcher          "
echo "=========================================================="

if [ -f "${TARGET_APPIMAGE}" ] && [ -s "${TARGET_APPIMAGE}" ]; then
    echo "  [✓] StreamingServiceLauncher ya está disponible en: ${TARGET_APPIMAGE}"
else
    echo "  -> Consultando última versión en GitHub..."
    LATEST_URL=$(curl -s "https://api.github.com/repos/aarron-lee/StreamingServiceLauncher/releases/latest" \
        | grep "browser_download_url" \
        | grep -E "StreamingServiceLauncher_.*_linux\.AppImage" \
        | cut -d '"' -f 4 \
        | head -n1 || true)

    if [ -n "${LATEST_URL}" ]; then
        echo "  -> Descargando StreamingServiceLauncher desde: ${LATEST_URL}..."
        TMP_FILE="${APP_DIR}/StreamingServiceLauncher.tmp"
        if curl -fSL --progress-bar "${LATEST_URL}" -o "${TMP_FILE}"; then
            mv -f "${TMP_FILE}" "${TARGET_APPIMAGE}"
            chmod +x "${TARGET_APPIMAGE}"
            echo "  [✓] StreamingServiceLauncher descargado con éxito."
        fi
    fi
fi

if [ -f "${TARGET_APPIMAGE}" ]; then
    chmod +x "${TARGET_APPIMAGE}"

    # Crear script CLI en ~/.local/bin/streaming-service-launcher
    cat << EOF_CLI > "${BIN_DIR}/streaming-service-launcher"
#!/bin/bash
"${TARGET_APPIMAGE}" --appname=\$1 --no-sandbox
EOF_CLI
    chmod +x "${BIN_DIR}/streaming-service-launcher"

    # Acceso directo .desktop
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

    echo "  [✓] Comando disponible: ${BIN_DIR}/streaming-service-launcher <nombre_servicio>"
    echo "  [✓] Acceso directo registrado en el menú de aplicaciones."
fi
