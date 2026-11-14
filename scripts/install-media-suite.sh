#!/usr/bin/env bash
# ==============================================================================
# install-media-suite.sh - Suite de Streaming, Películas Gratis, Torrents y Descargas
# ==============================================================================
# Incluye:
# 1. qBittorrent + Motores de búsqueda integrados (DonTorrent, ThePirateBay, 1337x...)
# 2. Stremio (Streaming de películas y series sin coste con add-ons como Torrentio)
# 3. Kodi (Centro multimedia universal y streaming avanzado)
# 4. JDownloader 2 (Gestor de descargas directas multihilo)
# 5. VLC Media Player (Reproductor universal sin dependencias de códecs)
# 6. FreeTube (Cliente privado de YouTube sin anuncios ni tracking)
# 7. Jellyfin Media Player (Streaming para servidores multimedia)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo "  Instalación de Suite de Streaming, Películas y Descargas"
echo "=========================================================="

# 1. Asegurar Flatpak
if ! command -v flatpak >/dev/null 2>&1; then
    echo "  [+] Instalando soporte Flatpak..."
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y flatpak
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y && sudo apt-get install -y flatpak
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm flatpak
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install flatpak
    fi
fi

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 2. Instalar aplicaciones de streaming y descargas
MEDIA_APPS=(
    "org.qbittorrent.qBittorrent"
    "org.jdownloader.JDownloader"
    "com.stremio.Stremio"
    "tv.kodi.Kodi"
    "org.videolan.VLC"
    "io.freetubeapp.FreeTube"
    "com.github.iwalton3.jellyfin-media-player"
)

INSTALLED_FLATPAKS=$(flatpak list --app --columns=application 2>/dev/null || true)
TO_INSTALL=()
for app in "${MEDIA_APPS[@]}"; do
    if ! echo "${INSTALLED_FLATPAKS}" | grep -qx "${app}"; then
        TO_INSTALL+=("${app}")
    fi
done

if [ ${#TO_INSTALL[@]} -gt 0 ]; then
    echo "[+] Instalando aplicaciones multimedia en lote único (${#TO_INSTALL[@]} apps)..."
    flatpak install -y --noninteractive flathub "${TO_INSTALL[@]}" || {
        for app in "${TO_INSTALL[@]}"; do
            flatpak install -y --noninteractive flathub "${app}" || true
        done
    }
else
    echo "  [✓] Todas las aplicaciones de la suite multimedia ya están instaladas."
fi

# 3. Configurar qBittorrent e instalar extensiones de búsqueda
echo ""
echo "[+] Configurando extensiones de búsqueda en qBittorrent..."
if [ -f "${SCRIPT_DIR}/configure-qbittorrent.sh" ]; then
    bash "${SCRIPT_DIR}/configure-qbittorrent.sh"
fi

# 4. Crear comandos CLI rápidos en ~/.local/bin
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"

declare -A LAUNCHERS=(
    ["qbittorrent"]="org.qbittorrent.qBittorrent"
    ["jdownloader"]="org.jdownloader.JDownloader"
    ["stremio"]="com.stremio.Stremio"
    ["kodi"]="tv.kodi.Kodi"
    ["vlc"]="org.videolan.VLC"
    ["freetube"]="io.freetubeapp.FreeTube"
    ["jellyfin"]="com.github.iwalton3.jellyfin-media-player"
)

for cmd in "${!LAUNCHERS[@]}"; do
    flatpak_id="${LAUNCHERS[$cmd]}"
    cat << EOF > "${BIN_DIR}/${cmd}"
#!/usr/bin/env bash
if command -v ${cmd} >/dev/null 2>&1 && [ "\$(command -v ${cmd})" != "${BIN_DIR}/${cmd}" ]; then
    exec \$(command -v ${cmd}) "\$@"
elif flatpak info "${flatpak_id}" >/dev/null 2>&1; then
    exec flatpak run "${flatpak_id}" "\$@"
else
    echo "La aplicación ${cmd} (${flatpak_id}) no está instalada."
    exit 1
fi
EOF
    chmod +x "${BIN_DIR}/${cmd}"
done

echo ""
echo "=========================================================="
echo " [✓] ¡Suite Multimedia, Películas y Descargas instalada!"
echo "=========================================================="
echo " Aplicaciones disponibles:"
echo "   stremio       -> Stremio (Películas y series en streaming)"
echo "   kodi          -> Kodi Media Center"
echo "   qbittorrent   -> qBittorrent (Con motores de búsqueda listos)"
echo "   jdownloader   -> JDownloader 2 (Descargas directas)"
echo "   vlc           -> Reproductor VLC"
echo "   freetube      -> YouTube sin anuncios ni tracking"
echo ""
echo " 💡 Consejos para ver películas y series sin coste:"
echo "   1. Stremio: Abre Stremio y ve a Add-ons (Complementos de la comunidad)."
echo "      Instala 'Torrentio' (https://torrentio.strem.fun) y 'CyberFlix'."
echo "   2. qBittorrent: Abre la pestaña 'Buscar' para buscar películas"
echo "      directamente en DonTorrent, ThePirateBay, 1337x o TorrentGalaxy."
echo "   3. Kodi: Puedes instalar addons en español como 'Balandro' o 'Alfa'."
echo "=========================================================="
