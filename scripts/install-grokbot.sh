#!/usr/bin/env bash
# ==============================================================================
# install-grokbot.sh - Instalador y configurador de Grok Bot (AppImage universal)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${HOME}/.local/share/grok-bot"
TARGET_APPIMAGE="${TARGET_DIR}/appimage"
ICON_TARGET_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"
ICON_FILE="${ICON_TARGET_DIR}/grok-bot.png"
DESKTOP_FILE="${HOME}/.local/share/applications/grok-bot.desktop"

echo "=========================================================="
echo "               Instalación de Grok Bot                    "
echo "=========================================================="

mkdir -p "${TARGET_DIR}" "${ICON_TARGET_DIR}" "${HOME}/.local/share/applications"

# 1. Copiar icono desde bundles si existe
if [ -f "${SCRIPT_DIR}/bundles/grok-bot.png" ]; then
    cp -f "${SCRIPT_DIR}/bundles/grok-bot.png" "${ICON_FILE}"
    echo "[✓] Icono de Grok Bot copiado a: ${ICON_FILE}"
fi

# 2. Localizar el AppImage
SOURCE_APPIMAGE=""
if [ -f "${TARGET_APPIMAGE}" ] && [ -s "${TARGET_APPIMAGE}" ]; then
    echo "[✓] Grok Bot ya está configurado en ${TARGET_APPIMAGE}."
    SOURCE_APPIMAGE="${TARGET_APPIMAGE}"
else
    # Buscar en Descargas
    FOUND_DOWNLOAD=$(find "${HOME}/Downloads" -maxdepth 1 -iname "*grok*bot*.appimage" 2>/dev/null | head -n1 || true)
    if [ -n "${FOUND_DOWNLOAD}" ] && [ -f "${FOUND_DOWNLOAD}" ]; then
        echo "[+] Encontrado AppImage en Descargas: ${FOUND_DOWNLOAD}"
        cp -f "${FOUND_DOWNLOAD}" "${TARGET_APPIMAGE}"
        chmod +x "${TARGET_APPIMAGE}"
        SOURCE_APPIMAGE="${TARGET_APPIMAGE}"
    else
        echo "[!] No se encontró el archivo AppImage de Grok Bot en ~/Downloads/ ni en ${TARGET_APPIMAGE}."
        echo "    Tip: Descarga el AppImage de Grok Bot y colócalo en ~/Downloads/ o ejecuta:"
        echo "    cp /ruta/a/Grok_Bot.AppImage ~/.local/share/grok-bot/appimage && chmod +x ~/.local/share/grok-bot/appimage"
    fi
fi

# 3. Generar acceso directo .desktop
cat << EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Type=Application
X-GrokBot-Integrator=appimage
Name=Grok Bot
Exec=${TARGET_APPIMAGE} %U
Icon=grok-bot
Terminal=false
StartupWMClass=grok-bot
MimeType=x-scheme-handler/grokbot;x-scheme-handler/sand;
Categories=Utility;Network;
EOF

chmod +x "${DESKTOP_FILE}"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
fi

echo "[✓] Acceso directo para Grok Bot configurado en: ${DESKTOP_FILE}"
echo "[✓] Grok Bot aparecerá en tu menú de aplicaciones."
