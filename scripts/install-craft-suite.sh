#!/usr/bin/env bash
# ==============================================================================
# install-craft-suite.sh - Instalador de ArtCraft Launcher y Suite Craft
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

BUNDLE_PATH="${REPO_DIR}/bundles/artcraft-launcher-0.6.0-linux-x86_64.flatpak"
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"

echo "=== Suite Craft (ArtCraft) ==="

if [ "${ARCH}" != "x86_64" ]; then
    echo "  [i] Bundle ArtCraft es x86_64 (actual: ${ARCH}). Omitiendo."
    exit 0
fi

if ! command -v flatpak >/dev/null 2>&1; then
    echo "  [!] Flatpak no está instalado. Omitiendo Suite Craft."
    exit 0
fi

if flatpak info ai.storyteller.artcraft-launcher >/dev/null 2>&1; then
    echo "  [✓] ArtCraft Launcher ya está instalado."
elif [ -f "${BUNDLE_PATH}" ]; then
    echo "  [+] Instalando ArtCraft Launcher desde bundle local..."
    flatpak install --user --bundle -y --noninteractive "${BUNDLE_PATH}" 2>/dev/null || \
        echo "  [i] No se pudo instalar ArtCraft bundle (entorno sin sesión Flatpak/FUSE)."
fi

for app in gridcraft deckcraft pdfcraft wordcraft; do
    cat << EOF > "${BIN_DIR}/${app}"
#!/usr/bin/env bash
if flatpak info "ai.storyteller.${app}" >/dev/null 2>&1; then
    exec flatpak run "ai.storyteller.${app}" "\$@"
elif flatpak info "ai.storyteller.artcraft-launcher" >/dev/null 2>&1; then
    exec flatpak run "ai.storyteller.artcraft-launcher" "\$@"
else
    echo "[!] ArtCraft Launcher no está instalado."
    exit 1
fi
EOF
    chmod +x "${BIN_DIR}/${app}"
done

echo "  [✓] Lanzadores de Suite Craft configurados en ${BIN_DIR}."
