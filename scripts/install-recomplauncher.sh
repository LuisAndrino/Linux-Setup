#!/usr/bin/env bash
# ==============================================================================
# install-recomplauncher.sh - Instalador de RecompLauncher (N64 PC Ports)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== RecompLauncher ==="

if [ "${ARCH}" != "x86_64" ]; then
    echo "  [i] RecompLauncher es x86_64 (actual: ${ARCH})."
    exit 0
fi

TARGET_DIR="${HOME}/.local/share/recomp-launcher"
TARGET_APPIMAGE="${TARGET_DIR}/RecompLauncher.AppImage"
DESKTOP_FILE="${HOME}/.local/share/applications/recomp-launcher.desktop"
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${TARGET_DIR}" "${HOME}/.local/share/applications" "${BIN_DIR}"

if [ -f "${TARGET_APPIMAGE}" ] && [ -s "${TARGET_APPIMAGE}" ]; then
    echo "  [✓] RecompLauncher ya está instalado."
elif [ "${LINUX_SETUP_SKIP_LARGE_APPIMAGES:-0}" = "1" ]; then
    echo "  [i] RecompLauncher omitido por LINUX_SETUP_SKIP_LARGE_APPIMAGES=1."
else
    LATEST_URL="$(safe_fetch "https://api.github.com/repos/elripalda/RecompLauncher/releases" 20 \
        | grep "browser_download_url" \
        | grep -E "RecompLauncher_.*_amd64\.AppImage" \
        | cut -d '"' -f 4 \
        | head -n1 || true)"
    if [ -n "${LATEST_URL}" ]; then
        echo "  [+] Descargando RecompLauncher..."
        if safe_download "${LATEST_URL}" "${TARGET_APPIMAGE}" 240; then
            chmod +x "${TARGET_APPIMAGE}"
            echo "  [✓] RecompLauncher instalado."
        else
            echo "  [!] No se pudo descargar RecompLauncher."
        fi
    fi
fi

cat << 'EOF_CLI' > "${BIN_DIR}/recomp-launcher"
#!/usr/bin/env bash
TARGET="${HOME}/.local/share/recomp-launcher/RecompLauncher.AppImage"
[ -x "${TARGET}" ] || { echo "[!] RecompLauncher no encontrado."; exit 1; }
exec "${TARGET}" "$@"
EOF_CLI
chmod +x "${BIN_DIR}/recomp-launcher"

cat << EOF > "${DESKTOP_FILE}"
[Desktop Entry]
Type=Application
Name=Recomp Launcher
Comment=Launcher for Zelda 64 and N64 PC static recompilations
Exec=${BIN_DIR}/recomp-launcher %U
Icon=applications-games
Terminal=false
Categories=Game;Emulator;
EOF
chmod +x "${DESKTOP_FILE}"
