#!/usr/bin/env bash
# ==============================================================================
# configure-qbittorrent.sh - Configura plugins de búsqueda para qBittorrent
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Configuración de Motores de Búsqueda qBittorrent ==="

DIRS=(
    "${HOME}/.var/app/org.qbittorrent.qBittorrent/data/qBittorrent/nova3/engines"
    "${HOME}/.local/share/data/qBittorrent/nova3/engines"
    "${HOME}/.local/share/qBittorrent/nova3/engines"
)

for d in "${DIRS[@]}"; do
    mkdir -p "$d"
done

declare -A PLUGINS=(
    ["thepiratebay.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/piratebay.py"
    ["limetorrents.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/limetorrents.py"
    ["solidtorrents.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/solidtorrents.py"
    ["torlock.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/torlock.py"
    ["torrentproject.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/torrentproject.py"
    ["eztv.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/eztv.py"
    ["torrentgalaxy.py"]="https://raw.githubusercontent.com/LightDestory/qBittorrent-Search-Plugins/master/src/engines/torrentgalaxy.py"
    ["kickasstorrents.py"]="https://raw.githubusercontent.com/LightDestory/qBittorrent-Search-Plugins/master/src/engines/kickasstorrents.py"
    ["glotorrents.py"]="https://raw.githubusercontent.com/LightDestory/qBittorrent-Search-Plugins/master/src/engines/glotorrents.py"
)

TMP_DIR="/tmp/qbit-plugins-$$"
mkdir -p "${TMP_DIR}"
COUNT=0

for name in "${!PLUGINS[@]}"; do
    url="${PLUGINS[$name]}"
    if safe_download "$url" "${TMP_DIR}/${name}" 15 && [ -s "${TMP_DIR}/${name}" ]; then
        for d in "${DIRS[@]}"; do
            cp -f "${TMP_DIR}/${name}" "${d}/${name}"
        done
        COUNT=$((COUNT + 1))
    fi
done

rm -rf "${TMP_DIR}"
echo "  [✓] ${COUNT}/${#PLUGINS[@]} motores de búsqueda instalados para qBittorrent."
