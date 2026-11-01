#!/usr/bin/env bash
# ==============================================================================
# install-openbot.sh - Instalador y configurador de OpenBot (Nightly Labs)
# ==============================================================================
# OpenBot: Local-first desktop workspace for persistent AI teammates
# Repositorio: https://github.com/nightly-labs/openbot
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${HOME}/.local/share/openbot"
TARGET_APPIMAGE="${TARGET_DIR}/OpenBot.AppImage"
ICON_TARGET_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"
ICON_FILE="${ICON_TARGET_DIR}/openbot.png"
DESKTOP_FILE="${HOME}/.local/share/applications/openbot.desktop"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "${TARGET_DIR}" "${ICON_TARGET_DIR}" "${HOME}/.local/share/applications" "${BIN_DIR}"

echo "=========================================================="
echo "          Instalación de OpenBot (AI Teammates)           "
echo "=========================================================="

ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)
        ASSET_SUFFIX="x86_64.AppImage"
        ;;
    aarch64|arm64)
        ASSET_SUFFIX="arm64.AppImage"
        ;;
    *)
        echo "[!] Arquitectura no soportada directamente para OpenBot AppImage: ${ARCH}"
        exit 1
        ;;
esac

# 1. Localizar o descargar el AppImage
if [ -f "${TARGET_APPIMAGE}" ] && [ -s "${TARGET_APPIMAGE}" ]; then
    echo "  [✓] OpenBot ya está instalado en: ${TARGET_APPIMAGE}"
else
    # Buscar si el usuario ya lo descargó en ~/Downloads
    FOUND_DOWNLOAD=$(find "${HOME}/Downloads" -maxdepth 1 -iname "*openbot*${ASSET_SUFFIX}*" 2>/dev/null | head -n1 || true)
    if [ -n "${FOUND_DOWNLOAD}" ] && [ -f "${FOUND_DOWNLOAD}" ]; then
        echo "  [+] Encontrado instalador en Descargas: ${FOUND_DOWNLOAD}"
        cp -f "${FOUND_DOWNLOAD}" "${TARGET_APPIMAGE}"
        chmod +x "${TARGET_APPIMAGE}"
    else
        echo "  -> Consultando última versión de OpenBot en GitHub Releases..."
        LATEST_URL=$(curl -s "https://api.github.com/repos/nightly-labs/openbot/releases/latest" \
            | grep "browser_download_url" \
            | grep -E "OpenBot-.*-${ASSET_SUFFIX}" \
            | cut -d '"' -f 4 \
            | head -n1 || true)

        if [ -n "${LATEST_URL}" ]; then
            echo "  -> Descargando OpenBot desde: ${LATEST_URL}..."
            TMP_FILE="${TARGET_DIR}/OpenBot.tmp"
            if curl -fSL --progress-bar "${LATEST_URL}" -o "${TMP_FILE}"; then
                mv -f "${TMP_FILE}" "${TARGET_APPIMAGE}"
                chmod +x "${TARGET_APPIMAGE}"
                echo "  [✓] OpenBot descargado e instalado correctamente."
            else
                rm -f "${TMP_FILE}"
                echo "  [!] Falló la descarga automática de OpenBot."
                echo "      Puedes descargarlo manualmente desde: https://github.com/nightly-labs/openbot/releases"
                echo "      y colocarlo en: ${TARGET_APPIMAGE}"
            fi
        else
            echo "  [!] No se pudo obtener la URL de descarga automáticamente (límite de API de GitHub o sin conexión)."
            echo "      Descárgalo desde https://github.com/nightly-labs/openbot/releases"
            echo "      y guárdalo como: ${TARGET_APPIMAGE}"
        fi
    fi
fi

# 2. Configurar Icono
if [ ! -f "${ICON_FILE}" ]; then
    # Intentar extraer el icono desde el AppImage si existe
    if [ -f "${TARGET_APPIMAGE}" ] && [ -x "${TARGET_APPIMAGE}" ]; then
        TMP_EXTRACT=$(mktemp -d)
        (
            cd "${TMP_EXTRACT}"
            "${TARGET_APPIMAGE}" --appimage-extract "*.png" 2>/dev/null || true
            FOUND_ICON=$(find "${TMP_EXTRACT}" -iname "*openbot*.png" -o -iname "*.DirIcon" 2>/dev/null | head -n1 || true)
            if [ -n "${FOUND_ICON}" ] && [ -f "${FOUND_ICON}" ]; then
                cp -f "${FOUND_ICON}" "${ICON_FILE}"
            fi
        ) || true
        rm -rf "${TMP_EXTRACT}"
    fi

    # Fallback si no se pudo extraer: descargar favicon / logo de openbot
    if [ ! -f "${ICON_FILE}" ]; then
        curl -sL "https://openbot.run/favicon.ico" -o "${ICON_FILE}" 2>/dev/null || true
    fi
fi

# 3. Crear script lanzador CLI en ~/.local/bin/openbot
cat << 'EOF_CLI' > "${BIN_DIR}/openbot"
#!/usr/bin/env bash
TARGET_APPIMAGE="${HOME}/.local/share/openbot/OpenBot.AppImage"
if [ ! -f "${TARGET_APPIMAGE}" ]; then
    echo "[!] No se encontró OpenBot en ${TARGET_APPIMAGE}."
    echo "    Ejecuta el instalador: install-openbot.sh"
    exit 1
fi
exec "${TARGET_APPIMAGE}" "$@"
EOF_CLI
chmod +x "${BIN_DIR}/openbot"
echo "  [✓] Comando CLI creado en: ${BIN_DIR}/openbot"

# 4. Crear acceso directo .desktop para el menú de aplicaciones
cat << EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Type=Application
Name=OpenBot
GenericName=AI Agent Workspace
Comment=Local-first desktop workspace for persistent AI teammates
Exec=${BIN_DIR}/openbot %U
Icon=${ICON_FILE}
Terminal=false
StartupWMClass=OpenBot
Categories=Development;Utility;ArtificialIntelligence;
MimeType=x-scheme-handler/openbot;
EOF

chmod +x "${DESKTOP_FILE}"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
fi

echo "  [✓] Acceso directo para OpenBot creado en: ${DESKTOP_FILE}"
echo "=========================================================="
echo " [✓] Instalación de OpenBot finalizada."
echo "     Puedes abrirlo desde el menú de aplicaciones o escribiendo 'openbot' o 'agent openbot'."
echo "=========================================================="
