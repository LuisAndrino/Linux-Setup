#!/usr/bin/env bash
# ==============================================================================
# setup.sh - Instalador Universal y Modular para Cualquier Distribución Linux
# ==============================================================================
# Soporta: Ubuntu/Debian, Fedora, Arch/Manjaro, openSUSE, Bazzite, SteamOS, etc.
# ==============================================================================

set -uo pipefail

# Colores para la terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="${SCRIPT_DIR}/packages/flatpak-apps.txt"
CLI_HELPER="${SCRIPT_DIR}/packages/cli-packages.sh"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

print_header() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
======================================================================
  _     _                  ____       _               
 | |   (_)_ __  _   ___  _/ ___|  ___| |_ _   _ _ __  
 | |   | | '_ \| | | \ \/ /\___ \ / _ \ __| | | | '_ \ 
 | |___| | | | | |_| |>  <  ___) |  __/ |_| |_| | |_) |
 |_____|_|_| |_|\__,_/_/\_\|____/ \___|\__|\__,_| .__/ 
                                                |_|    
   Configurador Universal de Software para Linux
======================================================================
EOF
    echo -e "${NC}"
}

show_help() {
    echo -e "${BOLD}Uso:${NC} ./setup.sh [OPCIONES]"
    echo ""
    echo "Comando para instalar TODO desatendido:"
    echo "  ${CYAN}./setup.sh --yes${NC}   o   ${CYAN}./setup.sh --all${NC}"
    echo ""
    echo "Opciones principales:"
    echo "  -y, --yes, --all  Instala TODO de forma automática y desatendida [Recomendado]"
    echo "  --native          Instala programas en versión NATIVA (Brave Origin, VS Code nativo,"
    echo "                    Steam, Tailscale, Antigravity, PowerShell, Terminal rápida (Alacritty),"
    echo "                    Grok Bot, Craft Suite, CLI + Flatpaks complementarios) [Recomendado]"
    echo "  --flatpak-only    Instala todo mediante Flatpak (Ideal para Bazzite/SteamOS inmutables)"
    echo "  --gaming          Instala solo herramientas y launchers de Gaming (Lutris, Heroic, Prism, Gamescope, etc.)"
    echo "  --gamescope       Instala y optimiza Valve Gamescope (micro-compositor FSR/HDR)"
    echo "  --cli             Instala solo herramientas de terminal y paquetes esenciales"
    echo "  --brave           Instala solo Brave Origin (repositorio nativo oficial)"
    echo "  --vscode          Instala solo Visual Studio Code (nativo con fallback a Flatpak)"
    echo "  --steam           Instala solo Steam"
    echo "  --tailscale       Instala y configura solo Tailscale"
    echo "  --antigravity     Instala Google Antigravity"
    echo "  --powershell      Instala Microsoft PowerShell (pwsh)"
    echo "  --terminal        Instala terminal rápida estilo Omarchy (Alacritty/Ghostty)"
    echo "  --grokbot         Instala y configura solo Grok Bot (AppImage)"
    echo "  --craft           Instala ArtCraft Launcher y la suite Craft (GridCraft, DeckCraft...)"
    echo "  --waydroid        Instala y configura Waydroid (Emulador Android en Linux)"
    echo "  --mysql           Instala MySQL Workbench (con parche XWayland) y DBeaver"
    echo "  --omarchy-desktop Instala el entorno gráfico estilo Omarchy (Hyprland, Waybar, temas, modo agentes)"
    echo "  --dry-run         Simula las acciones sin modificar el sistema"
    echo "  -h, --help        Muestra esta ayuda"
    echo ""
}

ensure_flatpak_installed() {
    if ! command -v flatpak >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] Flatpak no está instalado. Instalándolo mediante el gestor del sistema...${NC}"
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y flatpak
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y flatpak
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm --needed flatpak
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper --non-interactive install flatpak
        fi
    fi

    echo -e "${BLUE}[+] Verificando repositorio Flathub...${NC}"
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    echo -e "${GREEN}[✓] Flatpak y Flathub configurados.${NC}"
}

install_flatpaks() {
    echo -e "\n${BOLD}${CYAN}=== APLICACIONES FLATPAK COMPLEMENTARIAS ===${NC}"
    ensure_flatpak_installed

    if [ ! -f "${PACKAGES_FILE}" ]; then
        echo -e "${RED}[ERROR] No se encontró ${PACKAGES_FILE}${NC}"
        return 1
    fi

    local apps=()
    while IFS= read -r line || [ -n "$line" ]; do
        cleaned=$(echo "$line" | sed 's/#.*//' | xargs)
        if [ -n "$cleaned" ]; then
            apps+=("$cleaned")
        fi
    done < "${PACKAGES_FILE}"

    for app in "${apps[@]}"; do
        # Evitar duplicados si el usuario instaló versión nativa de Brave, VS Code o Steam
        if [ "$app" = "com.brave.Browser" ] && (command -v brave-origin >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1); then
            echo -e "  ${MAGENTA}[* Omitido]${NC} com.brave.Browser (Ya tienes instalado Brave Origin nativo)"
            continue
        fi

        if [ "$app" = "com.visualstudio.code" ] && command -v code >/dev/null 2>&1; then
            echo -e "  ${MAGENTA}[* Omitido]${NC} com.visualstudio.code (Ya tienes instalado VS Code nativo 'code')"
            continue
        fi

        if [ "$app" = "com.valvesoftware.Steam" ] && command -v steam >/dev/null 2>&1; then
            echo -e "  ${MAGENTA}[* Omitido]${NC} com.valvesoftware.Steam (Ya tienes instalado Steam nativo)"
            continue
        fi

        if flatpak info "$app" >/dev/null 2>&1; then
            echo -e "  ${GREEN}[✓ Ya instalado]${NC} $app"
        else
            echo -e "  ${YELLOW}[+] Instalando Flatpak:${NC} $app..."
            flatpak install -y --noninteractive flathub "$app" || echo -e "  ${RED}[✗ Error]${NC} $app"
        fi
    done
}

install_cli() {
    echo -e "\n${BOLD}${CYAN}=== HERRAMIENTAS CLI Y OPTIMIZACIONES DE SISTEMA ===${NC}"
    if [ -f "${CLI_HELPER}" ]; then
        # shellcheck source=/dev/null
        source "${CLI_HELPER}"
        install_essential_cli
    fi
}

install_brave_origin() {
    echo -e "\n${BOLD}${CYAN}=== BRAVE ORIGIN (NATIVO) ===${NC}"
    bash "${SCRIPTS_DIR}/install-brave.sh"
}

install_vscode() {
    echo -e "\n${BOLD}${CYAN}=== VISUAL STUDIO CODE ===${NC}"
    bash "${SCRIPTS_DIR}/install-vscode.sh" "${1:-false}"
}

install_steam() {
    echo -e "\n${BOLD}${CYAN}=== STEAM ===${NC}"
    bash "${SCRIPTS_DIR}/install-steam.sh" "${1:-false}"
}

install_tailscale() {
    echo -e "\n${BOLD}${CYAN}=== TAILSCALE ===${NC}"
    bash "${SCRIPTS_DIR}/install-tailscale.sh"
}

install_antigravity() {
    echo -e "\n${BOLD}${CYAN}=== GOOGLE ANTIGRAVITY ===${NC}"
    bash "${SCRIPTS_DIR}/install-antigravity.sh"
}

install_powershell() {
    echo -e "\n${BOLD}${CYAN}=== MICROSOFT POWERSHELL ===${NC}"
    bash "${SCRIPTS_DIR}/install-powershell.sh"
}

install_terminal() {
    echo -e "\n${BOLD}${CYAN}=== TERMINAL RÁPIDA (ALACRITTY / GHOSTTY - ESTILO OMARCHY) ===${NC}"
    bash "${SCRIPTS_DIR}/install-terminal.sh"
}

install_grokbot() {
    echo -e "\n${BOLD}${CYAN}=== GROK BOT ===${NC}"
    bash "${SCRIPTS_DIR}/install-grokbot.sh"
}

install_dev_tools() {
    echo -e "\n${BOLD}${CYAN}=== HERRAMIENTAS DEV (JAVA OPENJDK 21, LAZYGIT, MISE) ===${NC}"
    bash "${SCRIPTS_DIR}/install-dev-tools.sh"
}

install_craft_suite() {
    echo -e "\n${BOLD}${CYAN}=== SUITE CRAFT (ARTCRAFT, GRIDCRAFT, DECKCRAFT...) ===${NC}"
    bash "${SCRIPTS_DIR}/install-craft-suite.sh"
}

install_waydroid() {
    echo -e "\n${BOLD}${CYAN}=== EMULADOR ANDROID (WAYDROID) ===${NC}"
    bash "${SCRIPTS_DIR}/install-waydroid.sh"
}

install_mysql_workbench() {
    echo -e "\n${BOLD}${CYAN}=== MYSQL WORKBENCH & CLIENTES SQL ===${NC}"
    bash "${SCRIPTS_DIR}/install-mysql-workbench.sh"
}

install_gaming_suite() {
    echo -e "\n${BOLD}${CYAN}=== LAUNCHERS Y HERRAMIENTAS DE GAMING ===${NC}"
    install_steam "false"
    bash "${SCRIPTS_DIR}/install-gamescope.sh"
    ensure_flatpak_installed
    echo "[+] Instalando Launchers y compatibilidad (Lutris, Heroic, Prism, ProtonUp-Qt, Goverlay, Bottles, Ludusavi, AntiMicroX)..."
    flatpak install -y --noninteractive flathub \
        net.lutris.Lutris \
        com.heroicgameslauncher.hgl \
        org.prismlauncher.PrismLauncher \
        net.davidotek.pupgui2 \
        io.github.benjamimgois.goverlay \
        com.usebottles.bottles \
        com.github.Matoking.protontricks \
        com.vysp3r.ProtonPlus \
        com.github.mtkennerly.ludusavi \
        io.github.antimicrox.antimicrox || true
}

dry_run() {
    echo -e "${YELLOW}${BOLD}--- MODO SIMULACIÓN (DRY-RUN) ---${NC}"
    echo "1. Programas Nativos / Especiales:"
    echo "   - Brave: Brave Origin (FLAVOR=origin)."
    echo "   - VS Code: Repositorio oficial Microsoft (code)."
    echo "   - Java: OpenJDK 21 (Requerido para Apache NetBeans y Prism Launcher)."
    echo "   - Herramientas Dev: Lazygit (Terminal UI Git), Mise (Gestor de runtimes)."
    echo "   - Steam: Paquete nativo de la distro o Steam Flatpak."
    echo "   - Gamescope: Micro-compositor de Valve con escalado FSR/NIS, HDR y limitador FPS."
    echo "   - Tailscale: Script oficial universal + activación systemd."
    echo "   - Antigravity: Instalador oficial de Google Antigravity."
    echo "   - PowerShell: Microsoft PowerShell (pwsh)."
    echo "   - Terminal rápida: Alacritty / Ghostty (GPU accelerated - estilo Omarchy)."
    echo "   - Grok Bot: AppImage en ~/.local/share/grok-bot + .desktop."
    echo "   - Suite Craft: ArtCraft Launcher (bundle) para GridCraft, DeckCraft, WordCraft y PdfCraft."
    echo "   - Waydroid: Emulador / contenedor Android con aceleración GPU nativa y Wayland."
    echo "   - Base de datos: MySQL Workbench (con fix GDK_BACKEND=x11) y DBeaver Community."
    echo ""
    echo "2. Gaming & Optimización:"
    echo "   - Gamescope (Micro-compositor Valve con escalado FSR/HDR), GameMode, MangoHud."
    echo "   - Lutris, Heroic Games Launcher, Prism Launcher (Minecraft)."
    echo "   - Ludusavi (Copia y sincronización de partidas guardadas de PC games)."
    echo "   - AntiMicroX (Mapeo de mandos a teclado/ratón)."
    echo "   - ProtonUp-Qt, Goverlay, Bottles, Protontricks, ProtonPlus."
    echo ""
    echo "3. Música, Audio y Voz:"
    echo "   - Easy Effects (Filtro IA de ruido para micro en Discord/Slack y ecualizador FLAC)."
    echo "   - ncspot (Cliente ligero de Spotify en Rust)."
    echo "   - Strawberry Music Player (Reproductor audiófilo de alta fidelidad FLAC)."
    echo "   - Amberol (Reproductor minimalista FLAC/local)."
    echo ""
    echo "4. Sincronización y Archivos:"
    echo "   - LocalSend (Transferencia local de archivos estilo AirDrop entre PC y móvil)."
    echo "   - Pika Backup (Copias de seguridad incrementales cifradas de tus carpetas)."
    echo "   - PeaZip (Gestor de compresión avanzado)."
    echo ""
    echo "5. Mensajería y Redes:"
    echo "   - WhatsApp (ZapZap), Telegram Desktop, Discord Oficial, Vesktop (Wayland audio), Slack."
    echo ""
    echo "6. Herramientas CLI del sistema:"
    echo "   - git, gh, curl, wget, jq, ripgrep, tree, rsync, htop, btop, tmux, zsh, build tools."
    echo ""
    echo "7. Productividad & Flatpaks complementarios:"
    grep -v '^#' "${PACKAGES_FILE}" | grep -v '^$' | while read -r line; do
        echo "   - $line"
    done
}

ACTION="interactive"

if [ $# -gt 0 ]; then
    case "$1" in
        -y|--yes|--all|--install-all|--native) ACTION="native" ;;
        --flatpak-only) ACTION="flatpak_only" ;;
        --gaming) ACTION="gaming" ;;
        --gamescope) ACTION="gamescope" ;;
        --cli) ACTION="cli" ;;
        --brave) ACTION="brave" ;;
        --vscode) ACTION="vscode" ;;
        --steam) ACTION="steam" ;;
        --tailscale) ACTION="tailscale" ;;
        --antigravity) ACTION="antigravity" ;;
        --powershell) ACTION="powershell" ;;
        --terminal) ACTION="terminal" ;;
        --grokbot) ACTION="grokbot" ;;
        --craft) ACTION="craft" ;;
        --devtools) ACTION="devtools" ;;
        --waydroid) ACTION="waydroid" ;;
        --mysql) ACTION="mysql" ;;
        --omarchy-desktop) ACTION="omarchy_desktop" ;;
        --dry-run) ACTION="dry-run" ;;
        -h|--help) show_help; exit 0 ;;
        *) echo -e "${RED}[!] Opción desconocida: $1${NC}"; show_help; exit 1 ;;
    esac
fi

print_header

if [ "$ACTION" = "dry-run" ]; then
    dry_run
    exit 0
fi

if [ "$ACTION" = "interactive" ]; then
    echo -e "${BOLD}¿Cómo deseas instalar tus programas?${NC}"
    echo "  1) Instalar TODO automáticamente (Modo Nativo + Gaming + Comunicación + CLI) [Recomendado]"
    echo "  2) Modo 100% Flatpak (Ideal para Bazzite, SteamOS o sistemas inmutables)"
    echo "  3) Solo Suite de Gaming (Lutris, Heroic, Prism, Steam, ProtonUp-Qt, Goverlay, Bottles)"
    echo "  4) Solo Desarrollo (Brave Origin, VS Code, NetBeans, PowerShell, Antigravity)"
    echo "  5) Solo Comunicación (WhatsApp ZapZap, Telegram, Discord, Vesktop, Slack)"
    echo "  6) Solo Música (ncspot [Rust], Strawberry FLAC, Amberol)"
    echo "  7) Solo Terminal rápida estilo Omarchy (Alacritty) y CLI"
    echo "  8) Solo Tailscale"
    echo "  9) Instalar Entorno Gráfico Completo estilo Omarchy (Hyprland + Waybar + Temas + Agentes)"
    echo "  10) Simulación (Dry run)"
    echo "  11) Salir"
    echo ""
    read -rp "Selecciona una opción [1-11] (por defecto 1): " choice
    choice=${choice:-1}

    case "$choice" in
        1) ACTION="native" ;;
        2) ACTION="flatpak_only" ;;
        3) ACTION="gaming" ;;
        4) ACTION="dev_tools" ;;
        5) ACTION="communication" ;;
        6) ACTION="audio" ;;
        7) ACTION="cli" ;;
        8) ACTION="tailscale" ;;
        9) ACTION="omarchy_desktop" ;;
        10) ACTION="dry-run" ;;
        11) echo "Cancelado."; exit 0 ;;
        *) echo "Opción no válida."; exit 1 ;;
    esac
fi

case "$ACTION" in
    native)
        install_cli
        install_brave_origin
        install_vscode "false"
        install_dev_tools
        install_steam "false"
        bash "${SCRIPTS_DIR}/install-gamescope.sh"
        install_tailscale
        install_antigravity
        install_powershell
        install_terminal
        install_grokbot
        install_craft_suite
        install_waydroid
        install_mysql_workbench
        install_flatpaks
        ;;
    flatpak_only)
        install_cli
        install_vscode "true"
        install_steam "true"
        install_tailscale
        install_antigravity
        install_powershell
        install_terminal
        install_grokbot
        install_craft_suite
        install_waydroid
        install_mysql_workbench
        install_flatpaks
        ;;
    gaming)
        install_gaming_suite
        ;;
    gamescope)
        bash "${SCRIPTS_DIR}/install-gamescope.sh"
        ;;
    brave)
        install_brave_origin
        ;;
    vscode)
        install_vscode "false"
        ;;
    steam)
        install_steam "false"
        ;;
    tailscale)
        install_tailscale
        ;;
    antigravity)
        install_antigravity
        ;;
    powershell)
        install_powershell
        ;;
    terminal)
        install_terminal
        ;;
    grokbot)
        install_grokbot
        ;;
    craft)
        install_craft_suite
        ;;
    devtools)
        install_dev_tools
        ;;
    waydroid)
        install_waydroid
        ;;
    mysql)
        install_mysql_workbench
        ;;
    dev_tools)
        install_brave_origin
        install_vscode "false"
        install_dev_tools
        install_antigravity
        install_powershell
        install_mysql_workbench
        flatpak install -y flathub org.apache.netbeans
        ;;
    communication)
        ensure_flatpak_installed
        flatpak install -y flathub com.rtosta.zapzap org.telegram.desktop com.discordapp.Discord dev.vencord.Vesktop com.slack.Slack
        ;;
    audio)
        ensure_flatpak_installed
        flatpak install -y flathub io.github.hrkfdn.ncspot org.strawberrymusicplayer.strawberry io.bassi.Amberol
        ;;
    cli)
        install_cli
        install_terminal
        ;;
    omarchy_desktop)
        bash "${SCRIPT_DIR}/omarchy-desktop/install.sh"
        ;;
    dry-run)
        dry_run
        ;;
esac

echo -e "\n${GREEN}${BOLD}======================================================================${NC}"
echo -e "${GREEN}${BOLD}  ¡Proceso finalizado con éxito!${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo -e "Recomendaciones:"
echo -e " - Conecta Tailscale: ${CYAN}sudo tailscale up${NC}"
echo -e " - Para iniciar PowerShell: ${CYAN}pwsh${NC}"
echo -e " - Para iniciar tu nueva terminal rápida: ${CYAN}alacritty${NC}"
echo -e " - Para escuchar Spotify en Rust por terminal: ${CYAN}flatpak run io.github.hrkfdn.ncspot${NC} (o ncspot)"
echo -e " - Para música FLAC de alta fidelidad: abre ${CYAN}Strawberry Music Player${NC}"
echo ""
