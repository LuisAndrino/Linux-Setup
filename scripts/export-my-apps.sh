#!/usr/bin/env bash
# ==============================================================================
# export-my-apps.sh - Exporta los programas instalados en la máquina actual
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FLATPAK="${SCRIPT_DIR}/packages/flatpak-apps.txt"
EXPORT_DIR="${SCRIPT_DIR}/packages/system-exports"

mkdir -p "${EXPORT_DIR}"

echo "=========================================================="
echo "      Exportador de Paquetes y Aplicaciones de Usuario    "
echo "=========================================================="

get_app_description() {
    case "$1" in
        "com.visualstudio.code") echo "Visual Studio Code" ;;
        "org.apache.netbeans") echo "Apache NetBeans IDE" ;;
        "com.valvesoftware.Steam") echo "Steam" ;;
        "net.lutris.Lutris") echo "Lutris (Gestor de juegos)" ;;
        "com.heroicgameslauncher.hgl") echo "Heroic Games Launcher (Epic/GOG)" ;;
        "org.prismlauncher.PrismLauncher") echo "Prism Launcher (Minecraft)" ;;
        "net.davidotek.pupgui2") echo "ProtonUp-Qt (Instalador GE-Proton)" ;;
        "io.github.benjamimgois.goverlay") echo "Goverlay (Configurador MangoHud/vkBasalt)" ;;
        "io.github.hrkfdn.ncspot") echo "ncspot (Cliente ligero Spotify en Rust)" ;;
        "org.strawberrymusicplayer.strawberry") echo "Strawberry Music Player (FLAC/Audiófilo)" ;;
        "io.bassi.Amberol") echo "Amberol (Reproductor música FLAC)" ;;
        "com.brave.Browser") echo "Navegador Brave" ;;
        "com.google.Chrome") echo "Google Chrome" ;;
        "org.mozilla.firefox") echo "Mozilla Firefox" ;;
        "com.onepassword.OnePassword") echo "1Password" ;;
        "org.videolan.VLC") echo "VLC Media Player" ;;
        "org.kde.haruna") echo "Haruna Video Player" ;;
        "org.kde.gwenview") echo "Visor de imágenes Gwenview" ;;
        "org.kde.okular") echo "Lector de PDF Okular" ;;
        "org.kde.kcalc") echo "Calculadora KCalc" ;;
        "com.github.tchx84.Flatseal") echo "Gestor de permisos Flatseal" ;;
        "io.github.flattool.Warehouse") echo "Gestor de Flatpaks Warehouse" ;;
        "io.github.DenysMb.Kontainer") echo "GUI de contenedores Kontainer" ;;
        "com.github.Matoking.protontricks") echo "Protontricks" ;;
        "com.vysp3r.ProtonPlus") echo "ProtonPlus" ;;
        "org.gnome.Firmware") echo "Actualizador de Firmware" ;;
        "com.rtosta.zapzap") echo "WhatsApp (ZapZap)" ;;
        "org.telegram.desktop") echo "Telegram Desktop" ;;
        "com.discordapp.Discord") echo "Discord Oficial" ;;
        "dev.vencord.Vesktop") echo "Vesktop (Discord Wayland)" ;;
        "com.slack.Slack") echo "Slack" ;;
        "com.usebottles.bottles") echo "Bottles (Gestor Wine/Proton)" ;;
        "org.flameshot.Flameshot") echo "Flameshot" ;;
        "md.obsidian.Obsidian") echo "Obsidian (Notas)" ;;
        "ai.storyteller.artcraft-launcher") echo "ArtCraft Launcher (Suite Craft)" ;;
        "ai.storyteller.gridcraft") echo "GridCraft (Hojas de cálculo)" ;;
        "ai.storyteller.deckcraft") echo "DeckCraft (Presentaciones)" ;;
        "ai.storyteller.pdfcraft") echo "PdfCraft (PDFs)" ;;
        "ai.storyteller.wordcraft") echo "WordCraft (Documentos)" ;;
        *) echo "" ;;
    esac
}

if command -v flatpak >/dev/null 2>&1; then
    echo "[+] Extrayendo Flatpaks instalados desde Flathub..."
    INSTALLED_FLATPAKS=$(flatpak list --app --columns=application,origin | awk '$2=="flathub" {print $1}' | sort -u)

    # Filtrar el spotify oficial si el usuario quiso reemplazarlo
    INSTALLED_FLATPAKS=$(echo "${INSTALLED_FLATPAKS}" | grep -v 'com.spotify.Client' || true)

    # Asegurar que las aplicaciones solicitadas se mantengan en la lista
    MUST_HAVE=(
        "com.visualstudio.code" "org.apache.netbeans" "com.valvesoftware.Steam"
        "net.lutris.Lutris" "com.heroicgameslauncher.hgl" "org.prismlauncher.PrismLauncher"
        "net.davidotek.pupgui2" "io.github.benjamimgois.goverlay"
        "io.github.hrkfdn.ncspot" "org.strawberrymusicplayer.strawberry" "io.bassi.Amberol"
        "com.rtosta.zapzap" "org.telegram.desktop" "com.discordapp.Discord"
        "dev.vencord.Vesktop" "com.slack.Slack" "com.usebottles.bottles"
        "org.flameshot.Flameshot" "md.obsidian.Obsidian"
    )

    TEMP_FILE=$(mktemp)
    cat << 'EOF' > "${TEMP_FILE}"
# ==============================================================================
# Lista de aplicaciones Flatpak (Flathub) - Actualizada automáticamente
# ==============================================================================
# Las líneas que empiezan por '#' son comentarios.
# Puedes añadir nuevos IDs de Flathub directamente aquí.
# ==============================================================================
EOF

    echo "# Fecha de última exportación: $(date)" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"

    ALL_FLATPAKS=$(printf "%s\n%s\n" "${INSTALLED_FLATPAKS}" "${MUST_HAVE[*]}" | tr ' ' '\n' | grep -v '^$' | sort -u)

    for app in ${ALL_FLATPAKS}; do
        desc=$(get_app_description "$app")
        if [ -n "$desc" ]; then
            printf "%-36s # %s\n" "$app" "$desc" >> "${TEMP_FILE}"
        else
            echo "$app" >> "${TEMP_FILE}"
        fi
    done

    mv "${TEMP_FILE}" "${OUTPUT_FLATPAK}"
    echo "[✓] Lista Flatpak actualizada en: ${OUTPUT_FLATPAK}"
    echo "    Total de aplicaciones Flatpak registradas: $(grep -v '^#' "${OUTPUT_FLATPAK}" | grep -v '^$' | wc -l)"
fi

echo "[+] Exportando lista de paquetes nativos del sistema..."

if command -v pacman >/dev/null 2>&1; then
    pacman -Qqe > "${EXPORT_DIR}/arch-packages.txt" 2>/dev/null || true
elif command -v dpkg >/dev/null 2>&1; then
    dpkg --get-selections | awk '{print $1}' > "${EXPORT_DIR}/debian-packages.txt" 2>/dev/null || true
elif command -v rpm >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        dnf repoquery --userinstalled --qf '%{name}' > "${EXPORT_DIR}/fedora-user-packages.txt" 2>/dev/null || true
    fi
    rpm -qa --qf '%{name}\n' | sort > "${EXPORT_DIR}/rpm-all-packages.txt" 2>/dev/null || true
fi

if command -v brew >/dev/null 2>&1; then
    brew leaves > "${EXPORT_DIR}/brew-formulae.txt" 2>/dev/null || true
    brew list --cask > "${EXPORT_DIR}/brew-casks.txt" 2>/dev/null || true
fi

echo ""
echo "=========================================================="
echo " ¡Exportación completada exitosamente!"
echo "=========================================================="
