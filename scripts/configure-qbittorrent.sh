#!/usr/bin/env bash
# ==============================================================================
# configure-qbittorrent.sh - Optimizador y descargador de motores de búsqueda
# ==============================================================================
# Instala plugins de búsqueda (ThePirateBay, 1337x, TorrentGalaxy, DonTorrent,
# EliteTorrent, Nyaa, Jackett, etc.) y activa la pestaña de búsqueda en qBittorrent.
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "    Configuración de qBittorrent y Motores de Búsqueda    "
echo "=========================================================="

# 1. Asegurar dependencias (Python3 es requerido por el motor de búsqueda de qBittorrent)
if ! command -v python3 >/dev/null 2>&1; then
    echo "  [+] Instalando Python 3 (requerido para los motores de búsqueda)..."
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3 python3-pip 2>/dev/null || true
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y 2>/dev/null || true
        sudo apt-get install -y python3 python3-pip 2>/dev/null || true
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm python python-pip 2>/dev/null || true
    fi
fi

# 2. Rutas objetivo (Tanto para instalación Flatpak como Nativa)
DIRS=(
    "${HOME}/.var/app/org.qbittorrent.qBittorrent/data/qBittorrent/nova3/engines"
    "${HOME}/.local/share/data/qBittorrent/nova3/engines"
    "${HOME}/.local/share/qBittorrent/nova3/engines"
)

for d in "${DIRS[@]}"; do
    mkdir -p "$d"
done

# 3. Lista de plugins curados de alta calidad
declare -A PLUGINS=(
    # Internacionales (Películas, Series, Música, Software)
    ["thepiratebay.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/piratebay.py"
    ["limetorrents.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/limetorrents.py"
    ["solidtorrents.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/solidtorrents.py"
    ["torlock.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/torlock.py"
    ["torrentproject.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/torrentproject.py"
    ["torrentgalaxy.py"]="https://raw.githubusercontent.com/LightDestory/qBittorrent-Search-Plugins/master/src/engines/torrentgalaxy.py"
    ["kickasstorrents.py"]="https://raw.githubusercontent.com/LightDestory/qBittorrent-Search-Plugins/master/src/engines/kickasstorrents.py"
    ["bitsearch.py"]="https://raw.githubusercontent.com/BurningMop/qBittorrent-Search-Plugins/refs/heads/main/bitsearch.py"
    ["eztv.py"]="https://raw.githubusercontent.com/DrPurp/eztvx-qbittorrent-plugin/main/eztvx.py"
    ["jackett.py"]="https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/jackett.py"
    ["prowlarr.py"]="https://raw.githubusercontent.com/MANCrimSon/prowlarr-qbittorrent-plugin/main/prowlarr.py"
    ["nyaa.py"]="https://raw.githubusercontent.com/phuongtailtranminh/qBittorrent-Nyaa-Search-Plugin/master/nyaa.py"
    ["goggames.py"]="https://raw.githubusercontent.com/tolotp/qbittorrent-search-plugins-de-busqueda/refs/heads/main/Plugins/goggames.py"
    ["onlinefix.py"]="https://raw.githubusercontent.com/caiocinel/onlinefix-qbittorrent-plugin/main/onlinefix.py"

    # En Español (Películas y Series en Castellano / Latino)
    ["dontorrent.py"]="https://raw.githubusercontent.com/BurningMop/qBittorrent-Search-Plugins/refs/heads/main/dontorrent.py"
    ["elitetorrent.py"]="https://raw.githubusercontent.com/iordic/qbittorrent-search-plugins/master/engines/elitetorrent.py"
    ["calidadtorrent.py"]="https://raw.githubusercontent.com/BurningMop/qBittorrent-Search-Plugins/refs/heads/main/calidadtorrent.py"
    ["divxtotal.py"]="https://raw.githubusercontent.com/BurningMop/qBittorrent-Search-Plugins/refs/heads/main/divxtotal.py"
    ["latteam.py"]="https://raw.githubusercontent.com/tolotp/qbittorrent-search-plugins-de-busqueda/refs/heads/main/Plugins/latteam.py"
)

echo "  [+] Descargando e instalando extensiones de búsqueda en paralelo..."
TMP_DIR=$(mktemp -d)

for file in "${!PLUGINS[@]}"; do
    (
        url="${PLUGINS[$file]}"
        target_tmp="${TMP_DIR}/${file}"
        if curl -sSL -m 10 "$url" -o "$target_tmp" && [ -s "$target_tmp" ]; then
            for d in "${DIRS[@]}"; do
                cp -f "$target_tmp" "$d/${file}"
            done
            echo "    * ${file} [OK]"
        else
            echo "    * ${file} [Omitido]"
        fi
    ) &
done
wait
rm -rf "$TMP_DIR"

# 4. Activar pestaña de búsqueda en los archivos de configuración de qBittorrent
CONFIG_FILES=(
    "${HOME}/.var/app/org.qbittorrent.qBittorrent/config/qBittorrent/qBittorrent.conf"
    "${HOME}/.config/qBittorrent/qBittorrent.conf"
)

for conf in "${CONFIG_FILES[@]}"; do
    mkdir -p "$(dirname "$conf")"
    if [ ! -f "$conf" ]; then
        cat << 'EOF_CONF' > "$conf"
[Preferences]
General\SearchEnginesEnabled=true
Search\EngineEnabled=true
EOF_CONF
    else
        if ! grep -q "Search.*Enabled" "$conf"; then
            sed -i '/\[Preferences\]/a General\\SearchEnginesEnabled=true\nSearch\\EngineEnabled=true' "$conf" 2>/dev/null || true
        fi
    fi
done

echo ""
echo "=========================================================="
echo " [✓] ¡Motores de búsqueda de qBittorrent listos!"
echo "     Al abrir qBittorrent encontrarás la pestaña 'Buscar'"
echo "     con DonTorrent, ThePirateBay, TorrentGalaxy, EZTV, Nyaa, etc."
echo "=========================================================="
