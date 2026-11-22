#!/usr/bin/env bash
# ==============================================================================
# install-claude-desktop.sh - Instalador multi-distro de Claude Desktop App GUI
# ==============================================================================
# Ubuntu/Debian: repositorio APT oficial firmado de Anthropic (claude-desktop)
# Fedora/Arch/openSUSE/Inmutables: AppImage mantenido (aaddrick/claude-desktop-debian)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"
TARGET_DIR="${HOME}/.local/share/claude-desktop"
TARGET_APPIMAGE="${TARGET_DIR}/Claude.AppImage"
ICON_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"
ICON_FILE="${ICON_DIR}/claude-desktop.png"
mkdir -p "${BIN_DIR}" "${APP_DIR}" "${TARGET_DIR}" "${ICON_DIR}"

echo "=== Claude Desktop App (GUI) ==="

if command -v claude-desktop >/dev/null 2>&1 || [ -x "${TARGET_APPIMAGE}" ]; then
    echo "  [✓] Claude Desktop ya está instalado."
    exit 0
fi

INSTALLED=false

# 1. Repositorio APT oficial de Anthropic (Ubuntu 22.04+ / Debian 12+)
if [ "${PKG_MGR}" = "apt" ] && { [ "${DEB_ARCH}" = "amd64" ] || [ "${DEB_ARCH}" = "arm64" ]; }; then
    echo "  [+] Configurando repositorio APT oficial de Anthropic para Claude Desktop..."
    run_root install -d -m 0755 /usr/share/keyrings
    if safe_download "https://downloads.claude.ai/claude-desktop/key.asc" "/tmp/claude-desktop-key.asc" 30; then
        run_root install -m 0644 /tmp/claude-desktop-key.asc /usr/share/keyrings/claude-desktop-archive-keyring.asc
        rm -f /tmp/claude-desktop-key.asc
        echo "deb [signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" | \
            run_root tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null
        apt_update_safe
        if apt_has_candidate claude-desktop; then
            apt_install_list claude-desktop
            if command -v claude-desktop >/dev/null 2>&1 || dpkg -s claude-desktop >/dev/null 2>&1; then
                INSTALLED=true
                echo "  [✓] Claude Desktop oficial instalado vía APT."
            fi
        fi
    fi
fi

# 2. AppImage multi-distro para Fedora, Arch, openSUSE, inmutables o fallback
if [ "${INSTALLED}" = false ]; then
    if [ "${LINUX_SETUP_SKIP_LARGE_APPIMAGES:-0}" = "1" ]; then
        echo "  [i] Claude Desktop AppImage omitido por LINUX_SETUP_SKIP_LARGE_APPIMAGES=1."
        exit 0
    fi

    if [ "${DEB_ARCH}" = "amd64" ] || [ "${DEB_ARCH}" = "arm64" ]; then
        echo "  [+] Consultando último AppImage de Claude Desktop para Linux (${DEB_ARCH})..."
        LATEST_URL="$(safe_fetch "https://api.github.com/repos/aaddrick/claude-desktop-debian/releases/latest" 25 \
            | grep "browser_download_url" \
            | grep -E "claude-desktop-.*-${DEB_ARCH}\.AppImage\"" \
            | cut -d '"' -f 4 \
            | head -n1 || true)"

        if [ -n "${LATEST_URL}" ]; then
            echo "  [+] Descargando Claude Desktop AppImage..."
            if safe_download "${LATEST_URL}" "${TARGET_APPIMAGE}" 300; then
                chmod +x "${TARGET_APPIMAGE}"
                INSTALLED=true
            fi
        fi
    fi

    if [ "${INSTALLED}" = true ] && [ -x "${TARGET_APPIMAGE}" ]; then
        if [ ! -f "${ICON_FILE}" ]; then
            TMP_EX="/tmp/claude-icon-$$"
            mkdir -p "${TMP_EX}"
            (
                cd "${TMP_EX}"
                timeout 20 "${TARGET_APPIMAGE}" --appimage-extract "*.png" >/dev/null 2>&1 || true
                FOUND_ICON="$(find "${TMP_EX}" -iname "*claude*.png" -o -iname "*.DirIcon" 2>/dev/null | head -n1 || true)"
                [ -n "${FOUND_ICON}" ] && [ -f "${FOUND_ICON}" ] && cp -f "${FOUND_ICON}" "${ICON_FILE}"
            ) || true
            rm -rf "${TMP_EX}"
        fi

        cat << 'EOF_CLI' > "${BIN_DIR}/claude-desktop"
#!/usr/bin/env bash
exec "${HOME}/.local/share/claude-desktop/Claude.AppImage" "$@"
EOF_CLI
        chmod +x "${BIN_DIR}/claude-desktop"

        cat << EOF > "${APP_DIR}/claude-desktop.desktop"
[Desktop Entry]
Type=Application
Name=Claude
Comment=Claude Desktop AI Assistant
Exec=${BIN_DIR}/claude-desktop %U
Icon=${ICON_FILE}
Terminal=false
StartupWMClass=Claude
MimeType=x-scheme-handler/claude;
Categories=Network;Utility;Development;
EOF
        chmod +x "${APP_DIR}/claude-desktop.desktop"
        command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "${APP_DIR}" 2>/dev/null || true
        echo "  [✓] Claude Desktop GUI instalado en ${TARGET_APPIMAGE}."
    else
        echo "  [!] No se pudo instalar Claude Desktop en este entorno."
    fi
fi
