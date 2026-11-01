#!/usr/bin/env bash
# ==============================================================================
# install-recomplauncher.sh - Instalador de RecompLauncher (N64 PC Ports)
# ==============================================================================
# Lanzador y gestor para juegos recompilados estáticamente para PC:
# Zelda: Majora's Mask y Ocarina of Time nativos a 60+ FPS y soporte de mandos
# Repositorio: https://github.com/elripalda/RecompLauncher
# ==============================================================================
set -euo pipefail

TARGET_DIR="${HOME}/.local/share/recomp-launcher"
TARGET_APPIMAGE="${TARGET_DIR}/RecompLauncher.AppImage"
ICON_TARGET_DIR="${HOME}/.local/share/icons/hicolor/256x256/apps"
ICON_FILE="${ICON_TARGET_DIR}/recomp-launcher.png"
DESKTOP_FILE="${HOME}/.local/share/applications/recomp-launcher.desktop"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "${TARGET_DIR}" "${ICON_TARGET_DIR}" "${HOME}/.local/share/applications" "${BIN_DIR}"

echo "=========================================================="
echo "    Instalación de RecompLauncher (N64 PC Recompilations) "
echo "=========================================================="

ARCH=$(uname -m)
if [ "${ARCH}" != "x86_64" ]; then
    echo "  [!] RecompLauncher AppImage está compilado para x86_64 (actual: ${ARCH}). Omitiendo..."
    exit 0
fi

# 1. Localizar en ~/Downloads o descargar la última versión
if [ -f "${TARGET_APPIMAGE}" ] && [ -s "${TARGET_APPIMAGE}" ]; then
    echo "  [✓] RecompLauncher ya está instalado en: ${TARGET_APPIMAGE}"
else
    # Buscar si ya existe en ~/Downloads
    FOUND_DOWNLOAD=$(find "${HOME}/Downloads" -maxdepth 1 -iname "*recomp*launcher*amd64*.appimage" 2>/dev/null | head -n1 || true)
    if [ -n "${FOUND_DOWNLOAD}" ] && [ -f "${FOUND_DOWNLOAD}" ]; then
        echo "  [+] Encontrado instalador existente en Descargas: ${FOUND_DOWNLOAD}"
        cp -f "${FOUND_DOWNLOAD}" "${TARGET_APPIMAGE}"
        chmod +x "${TARGET_APPIMAGE}"
    else
        echo "  -> Consultando última versión de RecompLauncher en GitHub..."
        LATEST_URL=$(curl -s "https://api.github.com/repos/elripalda/RecompLauncher/releases" \
            | grep "browser_download_url" \
            | grep -E "RecompLauncher_.*_amd64\.AppImage" \
            | cut -d '"' -f 4 \
            | head -n1 || true)

        if [ -n "${LATEST_URL}" ]; then
            echo "  -> Descargando RecompLauncher desde: ${LATEST_URL}..."
            TMP_FILE="${TARGET_DIR}/RecompLauncher.tmp"
            if curl -fSL --progress-bar "${LATEST_URL}" -o "${TMP_FILE}"; then
                mv -f "${TMP_FILE}" "${TARGET_APPIMAGE}"
                chmod +x "${TARGET_APPIMAGE}"
                echo "  [✓] RecompLauncher descargado e instalado."
            else
                rm -f "${TMP_FILE}"
                echo "  [!] Error al descargar RecompLauncher."
            fi
        fi
    fi
fi

# 2. Configurar Icono
if [ ! -f "${ICON_FILE}" ] && [ -f "${TARGET_APPIMAGE}" ] && [ -x "${TARGET_APPIMAGE}" ]; then
    TMP_EXTRACT=$(mktemp -d)
    (
        cd "${TMP_EXTRACT}"
        "${TARGET_APPIMAGE}" --appimage-extract "*.png" 2>/dev/null || true
        FOUND_ICON=$(find "${TMP_EXTRACT}" -iname "*recomp*.png" -o -iname "*.DirIcon" 2>/dev/null | head -n1 || true)
        if [ -n "${FOUND_ICON}" ] && [ -f "${FOUND_ICON}" ]; then
            cp -f "${FOUND_ICON}" "${ICON_FILE}"
        fi
    ) || true
    rm -rf "${TMP_EXTRACT}"
fi

# 3. Crear comando CLI
cat << 'EOF_CLI' > "${BIN_DIR}/recomp-launcher"
#!/usr/bin/env bash
TARGET="${HOME}/.local/share/recomp-launcher/RecompLauncher.AppImage"
if [ ! -f "${TARGET}" ]; then
    echo "[!] No se encontró RecompLauncher en ${TARGET}."
    exit 1
fi
exec "${TARGET}" "$@"
EOF_CLI
chmod +x "${BIN_DIR}/recomp-launcher"

# 4. Crear acceso directo .desktop
cat << EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Type=Application
Name=Recomp Launcher
GenericName=N64 PC Port Launcher
Comment=Launcher and manager for Zelda 64 and Nintendo 64 native static recompilations
Exec=${BIN_DIR}/recomp-launcher %U
Icon=${ICON_FILE}
Terminal=false
StartupWMClass=RecompLauncher
Categories=Game;Emulator;Utility;
EOF

chmod +x "${DESKTOP_FILE}"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
fi

echo "  [✓] RecompLauncher listo en: ${BIN_DIR}/recomp-launcher y menú de aplicaciones."
