#!/usr/bin/env bash
# ==============================================================================
# setup.sh - Instalador Universal y Modular para Cualquier Distribución Linux
# ==============================================================================
# Soporta: Debian, Ubuntu, Fedora, Arch Linux, Manjaro, openSUSE, Bazzite, SteamOS
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
   Configurador Universal de Software para Linux (Multi-Distro)
======================================================================
EOF
    echo -e "${NC}"
}

show_help() {
    echo -e "${BOLD}Uso:${NC} ./setup.sh [OPCIONES]"
    echo ""
    echo -e "Comando para instalar TODO desatendido:"
    echo -e "  ${CYAN}./setup.sh --yes${NC}   o   ${CYAN}./setup.sh --all${NC}"
    echo ""
    echo -e "Opciones principales:"
    echo -e "  ${CYAN}-y, --yes, --all${NC}   Instala TODO de forma automática (Desarrollo, IA, Gaming, Multimedia, CLI) [Recomendado]"
    echo -e "  ${CYAN}--native${NC}           Instala herramientas y aplicaciones en modo nativo donde aplique"
    echo -e "  ${CYAN}--flatpak-only${NC}     Instala todo mediante Flatpak (Ideal para Bazzite, SteamOS o distros inmutables)"
    echo -e "  ${CYAN}--dev, --devtools${NC}  Instala la suite completa de desarrollo (Neovim, Lazygit, Mise, uv, Bun, Java, gh)"
    echo -e "  ${CYAN}--neovim${NC}           Instala Neovim v0.10+ y su configuración moderna en Lua (Lazy.nvim, Treesitter, Telescope)"
    echo -e "  ${CYAN}--ai, --ai-tools${NC}   Instala la suite de IA (Ollama local, Claude Code CLI, Aider, Antigravity, Grok Bot, agent/c)"
    echo -e "  ${CYAN}--gaming${NC}           Instala la suite de Gaming (Steam, Lutris, Heroic, Prism, ProtonUp-Qt, Goverlay, Gamescope)"
    echo -e "  ${CYAN}--gaming-mode${NC}      Configura el modo 'Return to Gaming Mode' universal (SteamOS Gamepad UI en Gamescope)"
    echo -e "  ${CYAN}--multimedia${NC}       Instala la suite Multimedia (VLC, MPV, HandBrake, OBS Studio, Kdenlive, Krita, Audacity, GIMP, Blender, Spotify)"
    echo -e "  ${CYAN}--cli${NC}              Instala solo herramientas de terminal y paquetes esenciales cross-distro"
    echo -e "  ${CYAN}--brave${NC}            Instala solo Brave Origin (repositorio nativo oficial)"
    echo -e "  ${CYAN}--firefox${NC}          Instala solo Mozilla Firefox (nativo o Flatpak oficial)"
    echo -e "  ${CYAN}--vscode${NC}           Instala solo Visual Studio Code (nativo con fallback a Flatpak)"
    echo -e "  ${CYAN}--steam${NC}            Instala solo Steam"
    echo -e "  ${CYAN}--tailscale${NC}        Instala y configura solo Tailscale"
    echo -e "  ${CYAN}--antigravity${NC}      Instala Google Antigravity"
    echo -e "  ${CYAN}--powershell${NC}       Instala Microsoft PowerShell (pwsh)"
    echo -e "  ${CYAN}--terminal${NC}         Instala terminal rápida (Alacritty/Ghostty)"
    echo -e "  ${CYAN}--grokbot${NC}          Instala y configura solo Grok Bot (AppImage)"
    echo -e "  ${CYAN}--craft${NC}            Instala ArtCraft Launcher y la suite Craft (GridCraft, DeckCraft...)"
    echo -e "  ${CYAN}--waydroid${NC}         Instala y configura Waydroid (Emulador Android en Linux)"
    echo -e "  ${CYAN}--mysql${NC}            Instala MySQL Workbench (con parche XWayland) y DBeaver"
    echo -e "  ${CYAN}--dry-run${NC}          Simula las acciones sin modificar el sistema"
    echo -e "  ${CYAN}-h, --help${NC}         Muestra esta ayuda"
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

        if [ "$app" = "org.mozilla.firefox" ] && command -v firefox >/dev/null 2>&1; then
            echo -e "  ${MAGENTA}[* Omitido]${NC} org.mozilla.firefox (Ya tienes instalado Firefox nativo)"
            continue
        fi

        echo -e "${BLUE}[+] Instalando Flatpak:${NC} ${BOLD}${app}${NC}"
        flatpak install -y --noninteractive flathub "$app" || true
    done

    echo -e "${GREEN}[✓] Instalación de Flatpaks finalizada.${NC}"
}

install_cli() {
    echo -e "\n${BOLD}${CYAN}=== HERRAMIENTAS CLI, DESARROLLO Y GAMING (MULTI-DISTRO) ===${NC}"
    if [ -f "${CLI_HELPER}" ]; then
        # shellcheck source=/dev/null
        source "${CLI_HELPER}"
        install_essential_cli
    else
        echo -e "${RED}[!] Archivo ${CLI_HELPER} no encontrado.${NC}"
    fi
}

install_brave_origin() {
    echo -e "\n${BOLD}${CYAN}=== BRAVE BROWSER (ORIGIN) ===${NC}"
    bash "${SCRIPTS_DIR}/install-brave.sh"
}

install_firefox() {
    echo -e "\n${BOLD}${CYAN}=== MOZILLA FIREFOX ===${NC}"
    bash "${SCRIPTS_DIR}/install-firefox.sh"
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
    echo -e "\n${BOLD}${CYAN}=== TERMINAL RÁPIDA (ALACRITTY / GHOSTTY) ===${NC}"
    bash "${SCRIPTS_DIR}/install-terminal.sh"
}

install_grokbot() {
    echo -e "\n${BOLD}${CYAN}=== GROK BOT ===${NC}"
    bash "${SCRIPTS_DIR}/install-grokbot.sh"
}

install_dev_tools() {
    echo -e "\n${BOLD}${CYAN}=== HERRAMIENTAS DEV (NEOVIM, LAZYGIT, MISE, UV, BUN, JAVA) ===${NC}"
    bash "${SCRIPTS_DIR}/install-dev-tools.sh"
}

install_neovim() {
    echo -e "\n${BOLD}${CYAN}=== NEOVIM (V0.10+ & LUA) ===${NC}"
    bash "${SCRIPTS_DIR}/install-neovim.sh"
}

install_ai_tools() {
    echo -e "\n${BOLD}${CYAN}=== SUITE DE INTELIGENCIA ARTIFICIAL ===${NC}"
    bash "${SCRIPTS_DIR}/install-ai-tools.sh"
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
    echo -e "\n${BOLD}${CYAN}=== SUITE INTEGRAL DE GAMING ===${NC}"
    install_steam "false"
    bash "${SCRIPTS_DIR}/install-gamescope.sh"
    bash "${SCRIPTS_DIR}/install-gaming-mode.sh"
    ensure_flatpak_installed
    echo "[+] Instalando Launchers y compatibilidad de gaming..."
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
        io.github.antimicrox.antimicrox \
        org.libretro.RetroArch \
        io.github.streetpea.Chiaki4deck \
        com.steamgriddb.SGDBoop || true
}

install_multimedia_suite() {
    echo -e "\n${BOLD}${CYAN}=== SUITE MULTIMEDIA Y CREACIÓN DE CONTENIDO ===${NC}"
    ensure_flatpak_installed
    echo "[+] Instalando aplicaciones multimedia, audio, video y diseño..."
    flatpak install -y --noninteractive flathub \
        org.videolan.VLC \
        io.mpv.Mpv \
        fr.handbrake.ghb \
        com.obsproject.Studio \
        org.kde.kdenlive \
        org.audacityteam.Audacity \
        org.kde.krita \
        org.gimp.GIMP \
        org.blender.Blender \
        org.kde.haruna \
        org.strawberrymusicplayer.strawberry \
        io.bassi.Amberol \
        com.spotify.Client || true
}

dry_run() {
    echo -e "${YELLOW}${BOLD}--- MODO SIMULACIÓN (DRY-RUN) ---${NC}"
    echo "1. Desarrollo y Programación:"
    echo "   - Neovim v0.10+ con configuración Lua (Lazy.nvim, Treesitter, Telescope, Which-Key)."
    echo "   - Lazygit (Terminal UI Git), Mise (Gestor de runtimes Node/Python/Rust/Java/Go)."
    echo "   - Astral uv (Gestor Python ultra-rápido) y Bun (Runtime JS/TS)."
    echo "   - Java OpenJDK 21 LTS y GitHub CLI (gh)."
    echo "   - Visual Studio Code nativo o Flatpak."
    echo ""
    echo "2. Suite de Inteligencia Artificial:"
    echo "   - Ollama (Ejecución local de LLMs como Llama 3, DeepSeek, Mistral)."
    echo "   - Claude Code CLI (@anthropic-ai/claude-code)."
    echo "   - Aider (AI Pair Programming en terminal con Git)."
    echo "   - Google Antigravity Agent & Grok Bot."
    echo "   - Atajos rápidos de terminal: 'c' y 'agent'."
    echo ""
    echo "3. Gaming y Emulación:"
    echo "   - Steam, Gamescope (Micro-compositor Valve con escalado FSR/HDR), GameMode, MangoHud."
    echo "   - Lutris, Heroic Games Launcher, Prism Launcher (Minecraft)."
    echo "   - RetroArch (Emulación retro) y Chiaki4deck (PlayStation Remote Play)."
    echo "   - Ludusavi (Sincronización de saves), ProtonUp-Qt, Goverlay, Bottles, Protontricks."
    echo ""
    echo "4. Multimedia y Creación:"
    echo "   - VLC, MPV (Ultra-ligero), Haruna, HandBrake (Transcodificación de video)."
    echo "   - OBS Studio (Streaming y grabación), Kdenlive (Edición de video)."
    echo "   - Krita (Pintura digital), GIMP (Edición fotográfica), Blender (3D y animación)."
    echo "   - Audacity, Strawberry Music Player (FLAC audiófilo), Amberol, Spotify."
    echo ""
    echo "5. Navegación, Sistema y Utilidades:"
    echo "   - Brave Origin, Tailscale, PowerShell, Terminal Alacritty."
    echo "   - Base de datos: MySQL Workbench y DBeaver Community."
    echo "   - Waydroid (Android container) y Suite Craft (ArtCraft)."
    echo "   - Comunicación: Discord, Vesktop, Telegram, WhatsApp ZapZap, Slack."
    echo ""
}

# Comprobar argumentos
ACTION="interactive"
if [ $# -gt 0 ]; then
    case "$1" in
        -y|--yes|--all|--install-all|--native) ACTION="native" ;;
        --flatpak-only) ACTION="flatpak_only" ;;
        --dev|--devtools) ACTION="dev_tools" ;;
        --neovim) ACTION="neovim" ;;
        --ai|--ai-tools) ACTION="ai" ;;
        --gaming) ACTION="gaming" ;;
        --gaming-mode) ACTION="gaming_mode" ;;
        --multimedia) ACTION="multimedia" ;;
        --gamescope) ACTION="gamescope" ;;
        --cli) ACTION="cli" ;;
        --brave) ACTION="brave" ;;
        --firefox) ACTION="firefox" ;;
        --vscode) ACTION="vscode" ;;
        --steam) ACTION="steam" ;;
        --tailscale) ACTION="tailscale" ;;
        --antigravity) ACTION="antigravity" ;;
        --powershell) ACTION="powershell" ;;
        --terminal) ACTION="terminal" ;;
        --grokbot) ACTION="grokbot" ;;
        --craft) ACTION="craft" ;;
        --waydroid) ACTION="waydroid" ;;
        --mysql) ACTION="mysql" ;;
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
    echo "  1) Instalar TODO automáticamente (Desarrollo + IA + Gaming + Multimedia + CLI) [Recomendado]"
    echo "  2) Modo 100% Flatpak (Ideal para Bazzite, SteamOS o distros inmutables)"
    echo "  3) Suite de Desarrollo (Neovim, Lazygit, Mise, uv, Bun, Java, GitHub CLI)"
    echo "  4) Suite de Inteligencia Artificial (Ollama, Claude Code, Aider, Antigravity, Grok Bot)"
    echo "  5) Suite de Gaming (Steam, Lutris, Heroic, Prism, RetroArch, ProtonUp-Qt, Goverlay)"
    echo "  6) Suite Multimedia y Creación (OBS Studio, VLC, MPV, HandBrake, Krita, Audacity, GIMP, Blender)"
    echo "  7) Solo Comunicación (WhatsApp ZapZap, Telegram, Discord, Vesktop, Slack)"
    echo "  8) Solo Música (Spotify, ncspot [Rust], Strawberry FLAC, Amberol)"
    echo "  9) Solo Terminal rápida (Alacritty) y utilidades CLI"
    echo "  10) Solo Tailscale"
    echo "  11) Simulación (Dry run)"
    echo "  12) Salir"
    echo ""
    read -rp "Selecciona una opción [1-12] (por defecto 1): " choice
    choice=${choice:-1}

    case "$choice" in
        1) ACTION="native" ;;
        2) ACTION="flatpak_only" ;;
        3) ACTION="dev_tools" ;;
        4) ACTION="ai" ;;
        5) ACTION="gaming" ;;
        6) ACTION="multimedia" ;;
        7) ACTION="communication" ;;
        8) ACTION="audio" ;;
        9) ACTION="cli" ;;
        10) ACTION="tailscale" ;;
        11) ACTION="dry-run" ;;
        12) echo "Cancelado."; exit 0 ;;
        *) echo "Opción no válida."; exit 1 ;;
    esac
fi

case "$ACTION" in
    native)
        install_cli
        install_dev_tools
        install_ai_tools
        install_brave_origin
        install_firefox
        install_vscode "false"
        install_steam "false"
        bash "${SCRIPTS_DIR}/install-gamescope.sh"
        bash "${SCRIPTS_DIR}/install-gaming-mode.sh"
        install_tailscale
        install_powershell
        install_terminal
        install_craft_suite
        install_waydroid
        install_mysql_workbench
        install_flatpaks
        ;;
    flatpak_only)
        install_cli
        install_dev_tools
        install_ai_tools
        install_firefox
        install_vscode "true"
        install_steam "true"
        bash "${SCRIPTS_DIR}/install-gamescope.sh"
        bash "${SCRIPTS_DIR}/install-gaming-mode.sh"
        install_tailscale
        install_powershell
        install_terminal
        install_craft_suite
        install_waydroid
        install_mysql_workbench
        install_flatpaks
        ;;
    dev_tools)
        install_dev_tools
        install_vscode "false"
        ;;
    neovim)
        install_neovim
        ;;
    ai)
        install_ai_tools
        ;;
    gaming)
        install_gaming_suite
        ;;
    gaming_mode)
        bash "${SCRIPTS_DIR}/install-gamescope.sh"
        bash "${SCRIPTS_DIR}/install-gaming-mode.sh"
        ;;
    multimedia)
        install_multimedia_suite
        ;;
    gamescope)
        bash "${SCRIPTS_DIR}/install-gamescope.sh"
        ;;
    brave)
        install_brave_origin
        ;;
    firefox)
        install_firefox
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
    waydroid)
        install_waydroid
        ;;
    mysql)
        install_mysql_workbench
        flatpak install -y flathub org.apache.netbeans
        ;;
    communication)
        ensure_flatpak_installed
        flatpak install -y flathub com.rtosta.zapzap org.telegram.desktop com.discordapp.Discord dev.vencord.Vesktop com.slack.Slack
        ;;
    audio)
        ensure_flatpak_installed
        flatpak install -y flathub io.github.hrkfdn.ncspot org.strawberrymusicplayer.strawberry io.bassi.Amberol com.spotify.Client
        ;;
    cli)
        install_cli
        install_terminal
        ;;
    dry-run)
        dry_run
        ;;
esac

echo -e "\n${GREEN}${BOLD}======================================================================${NC}"
echo -e "${GREEN}${BOLD}  ¡Proceso finalizado con éxito!${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo -e "Herramientas listas para usar:"
echo -e " - Neovim (v0.10+ con Lua & plugins): ${CYAN}nvim${NC}"
echo -e " - Git UI ultra-rápida: ${CYAN}lazygit${NC}"
echo -e " - Inteligencia Artificial: ${CYAN}ollama${NC}, ${CYAN}claude${NC}, ${CYAN}aider${NC}, ${CYAN}agent${NC} o ${CYAN}c${NC}"
echo -e " - Python ultrarrápido: ${CYAN}uv${NC} / JS-TS: ${CYAN}bun${NC}"
echo -e " - Terminal acelerada: ${CYAN}alacritty${NC}"
echo -e " - Conectar Tailscale: ${CYAN}sudo tailscale up${NC}"
echo ""
