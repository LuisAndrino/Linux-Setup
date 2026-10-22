#!/usr/bin/env bash
# ==============================================================================
# install-antigravity.sh - Instalador universal de Google Antigravity
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          Instalación de Google Antigravity               "
echo "=========================================================="

if command -v antigravity >/dev/null 2>&1; then
    echo "[✓] Antigravity ya está instalado en el sistema ($(command -v antigravity))."
    exit 0
fi

# 1. Opción Homebrew si brew está instalado
if command -v brew >/dev/null 2>&1; then
    echo "[+] Detectado Homebrew. Instalando Antigravity vía Cask..."
    if brew install --cask ublue-os/tap/antigravity-linux; then
        echo "[✓] Antigravity instalado exitosamente vía Homebrew."
        exit 0
    fi
fi

# 2. Instalación nativa mediante AppImage oficial de Google
INSTALL_DIR="${HOME}/.local/share/Antigravity"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"

mkdir -p "${INSTALL_DIR}" "${BIN_DIR}" "${DESKTOP_DIR}" "${ICON_DIR}"

echo "[+] Consultando última versión oficial de Antigravity en Google Cloud..."
MANIFEST_URL="https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/manifest/latest-x64-linux.yml"
APPIMAGE_URL=$(curl -fsSL "${MANIFEST_URL}" 2>/dev/null | grep -E 'url:.*Antigravity\.AppImage' | head -n1 | awk '{print $2}' || true)

if [ -z "${APPIMAGE_URL}" ]; then
    # URL de respaldo conocida
    APPIMAGE_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.25.0-6535192714805248/linux-x64/Antigravity.AppImage"
fi

TARGET_FILE="${INSTALL_DIR}/Antigravity.AppImage"
echo "[+] Descargando Antigravity desde ${APPIMAGE_URL}..."
curl -fL -o "${TARGET_FILE}" "${APPIMAGE_URL}"
chmod +x "${TARGET_FILE}"

# Symlink en ~/.local/bin
ln -sf "${TARGET_FILE}" "${BIN_DIR}/antigravity"

# Acceso directo .desktop
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

cat << EOF > "${DESKTOP_DIR}/antigravity-url-handler.desktop"
[Desktop Entry]
Name=Antigravity - URL Handler
Comment=Agent orchestration platform
GenericName=AI Agent Platform
Exec=${TARGET_FILE} "%U"
Icon=antigravity
Type=Application
NoDisplay=true
Terminal=false
StartupNotify=true
StartupWMClass=Antigravity
Categories=Utility;Development;
MimeType=x-scheme-handler/antigravity;
Keywords=antigravity;
EOF

# Actualizar base de datos de escritorio si existe comando
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
fi

echo "[✓] Google Antigravity instalado en: ${TARGET_FILE}"
echo "[✓] Ejecutable disponible en: ${BIN_DIR}/antigravity"
echo "[✓] Acceso directo registrado en tu menú de aplicaciones."
