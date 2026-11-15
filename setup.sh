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
    echo -e "  ${CYAN}-q, --quick, --quick-install${NC} Instalación rápida automatizada (ejecuta todo sin confirmaciones)"
    echo -e "  ${CYAN}--native${NC}           Instala herramientas y aplicaciones en modo nativo donde aplique"
    echo -e "  ${CYAN}--flatpak-only${NC}     Instala todo mediante Flatpak (Ideal para Bazzite, SteamOS o distros inmutables)"
    echo -e "  ${CYAN}--dev, --devtools${NC}  Instala la suite completa de desarrollo (Neovim, Lazygit, Mise, uv, Bun, Java, gh)"
    echo -e "  ${CYAN}--neovim${NC}           Instala Neovim v0.10+ y su configuración moderna en Lua (Lazy.nvim, Treesitter, Telescope)"
    echo -e "  ${CYAN}--ai, --ai-tools${NC}   Instala la suite de IA (Ollama local, Claude Code CLI, Aider, Antigravity, Grok Bot, agent/c)"
    echo -e "  ${CYAN}--gaming${NC}           Instala la suite de Gaming (Steam, Lutris, Heroic, Prism, ProtonUp-Qt, Goverlay, Gamescope)"
    echo -e "  ${CYAN}--gaming-mode${NC}      Configura el modo 'Return to Gaming Mode' universal (SteamOS Gamepad UI en Gamescope)"
    echo -e "  ${CYAN}--multimedia${NC}       Instala la suite Multimedia y Streaming (VLC, Stremio, Kodi, qBittorrent, JDownloader, OBS, Spotify)"
    echo -e "  ${CYAN}--creative${NC}         Instala la suite Creativa pesada (Blender, Kdenlive, Krita, GIMP, Audacity, HandBrake)"
    echo -e "  ${CYAN}--vm${NC}               Instala Virt-Manager (Máquinas Virtuales KVM/QEMU)"
    echo -e "  ${CYAN}--media, --movies${NC}  Instala suite de Streaming y Películas (Stremio, Kodi, qBittorrent, JDownloader, FreeTube)"
    echo -e "  ${CYAN}--qbittorrent${NC}     Instala qBittorrent y configura motores de búsqueda integrados"
    echo -e "  ${CYAN}--stremio${NC}         Instala Stremio (Streaming de películas y series sin costo)"
    echo -e "  ${CYAN}--kodi${NC}            Instala Kodi Media Center"
    echo -e "  ${CYAN}--jdownloader${NC}     Instala JDownloader 2 (Gestor de descargas directas)"
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
    echo -e "  ${CYAN}--openbot${NC}          Instala y configura OpenBot (Nightly Labs AI Workspace AppImage)"
    echo -e "  ${CYAN}--hex${NC}              Instala y configura Hex (Local Voice Dictation para Linux)"
    echo -e "  ${CYAN}--craft${NC}            Instala ArtCraft Launcher y la suite Craft (GridCraft, DeckCraft...)"
    echo -e "  ${CYAN}--homebrew${NC}         Instala y configura Homebrew para Linux"
    echo -e "  ${CYAN}--android${NC}          Instala Android SDK Platform Tools (adb & fastboot)"
    echo -e "  ${CYAN}--lsfg${NC}             Instala Lossless Scaling Frame Generation para Vulkan (lsfg-vk)"
    echo -e "  ${CYAN}--recomp${NC}           Instala RecompLauncher (Zelda N64 PC Ports)"
    echo -e "  ${CYAN}--streaming${NC}        Instala Streaming Service Launcher para Steam Game Mode"
    echo -e "  ${CYAN}--waydroid${NC}         Instala y configura Waydroid (Emulador Android en Linux)"
    echo -e "  ${CYAN}--tui, --archinstall${NC} Abre el selector interactivo estilo archinstall (muestra paquetes y detecta T14 Gen 2)"
    echo -e "  ${CYAN}--desktop-app${NC}      Crea acceso directo de aplicación de escritorio para el instalador interactivo"
    echo -e "  ${CYAN}--messaging${NC}        Instala clientes de WhatsApp (ZapZap) y Telegram Desktop"
    echo -e "  ${CYAN}--whatsapp${NC}         Instala solo cliente de WhatsApp (ZapZap)"
    echo -e "  ${CYAN}--telegram${NC}         Instala solo Telegram Desktop"
    echo -e "  ${CYAN}--communication${NC}    Instala WhatsApp, Telegram, Discord, Vesktop y Slack"
    echo -e "  ${CYAN}--mysql${NC}            Instala MySQL Workbench (con parche XWayland) y DBeaver"
    echo -e "  ${CYAN}--1password${NC}        Instala 1Password Desktop y 1Password CLI ('op')"
    echo -e "  ${CYAN}--optimize${NC}         Aplica optimizaciones de rendimiento (CPU, memoria, red BBR y AC para laptop)"
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
    if ! flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null; then
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    fi
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
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

    local installed_apps
    installed_apps=$(flatpak list --app --columns=application 2>/dev/null || true)

    local to_install=()
    for app in "${apps[@]}"; do
        # Evitar duplicados si el usuario instaló versión nativa de Brave, VS Code, Steam, Firefox o 1Password
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
        if [ "$app" = "com.onepassword.OnePassword" ] && command -v 1password >/dev/null 2>&1; then
            echo -e "  ${MAGENTA}[* Omitido]${NC} com.onepassword.OnePassword (Ya tienes instalado 1Password nativo)"
            continue
        fi

        if echo "${installed_apps}" | grep -qx "$app"; then
            echo -e "  ${GREEN}[✓ Ya instalado]${NC} ${app}"
            continue
        fi

        to_install+=("$app")
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo -e "${BLUE}[+] Instalando ${#to_install[@]} aplicaciones Flatpak en lote único (máxima velocidad)...${NC}"
        if ! flatpak install -y --noninteractive flathub "${to_install[@]}"; then
            echo -e "${YELLOW}[!] Reintentando en modo --user (sin requerir Polkit) o individualmente...${NC}"
            if ! flatpak install --user -y --noninteractive flathub "${to_install[@]}"; then
                for app in "${to_install[@]}"; do
                    flatpak install -y --noninteractive flathub "$app" 2>/dev/null || \
                    flatpak install --user -y --noninteractive flathub "$app" || true
                done
            fi
        fi
    else
        echo -e "${GREEN}[✓] Todas las aplicaciones Flatpak ya estaban instaladas.${NC}"
    fi

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

install_openbot() {
    echo -e "\n${BOLD}${CYAN}=== OPENBOT (AI TEAMMATES DESKTOP) ===${NC}"
    bash "${SCRIPTS_DIR}/install-openbot.sh"
}

install_hex() {
    echo -e "\n${BOLD}${CYAN}=== HEX (LOCAL VOICE DICTATION) ===${NC}"
    bash "${SCRIPTS_DIR}/install-hex.sh"
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

install_1password() {
    echo -e "\n${BOLD}${CYAN}=== 1PASSWORD (DESKTOP & CLI 'op') ===${NC}"
    bash "${SCRIPTS_DIR}/install-1password.sh"
}

install_homebrew() {
    echo -e "\n${BOLD}${CYAN}=== HOMEBREW PARA LINUX ===${NC}"
    bash "${SCRIPTS_DIR}/install-homebrew.sh"
}

install_android_tools() {
    echo -e "\n${BOLD}${CYAN}=== ANDROID PLATFORM TOOLS (ADB & FASTBOOT) ===${NC}"
    bash "${SCRIPTS_DIR}/install-android-tools.sh"
}

install_lsfg_vk() {
    echo -e "\n${BOLD}${CYAN}=== LOSSLESS SCALING FRAME GENERATION (LSFG-VK) ===${NC}"
    bash "${SCRIPTS_DIR}/install-lsfg-vk.sh"
}

install_recomplauncher() {
    echo -e "\n${BOLD}${CYAN}=== RECOMP LAUNCHER (N64 PC PORTS) ===${NC}"
    bash "${SCRIPTS_DIR}/install-recomplauncher.sh"
}

install_streaming_launcher() {
    echo -e "\n${BOLD}${CYAN}=== STREAMING SERVICE LAUNCHER (STEAM GAMING MODE) ===${NC}"
    bash "${SCRIPTS_DIR}/install-streaming-launcher.sh"
}

optimize_system() {
    echo -e "\n${BOLD}${CYAN}=== OPTIMIZACIONES DE RENDIMIENTO, HARDWARE Y RED ===${NC}"
    if [ -f "${SCRIPTS_DIR}/optimize-system.sh" ]; then
        if [ "$EUID" -eq 0 ]; then
            bash "${SCRIPTS_DIR}/optimize-system.sh"
        elif command -v sudo >/dev/null 2>&1; then
            sudo bash "${SCRIPTS_DIR}/optimize-system.sh" || true
        else
            bash "${SCRIPTS_DIR}/optimize-system.sh" || true
        fi
    fi
}

install_gaming_suite() {
    echo -e "\n${BOLD}${CYAN}=== SUITE INTEGRAL DE GAMING (ALTO RENDIMIENTO) ===${NC}"
    install_steam "false"
    bash "${SCRIPTS_DIR}/install-gamescope.sh"
    bash "${SCRIPTS_DIR}/install-gaming-mode.sh"
    bash "${SCRIPTS_DIR}/install-lsfg-vk.sh"
    bash "${SCRIPTS_DIR}/install-recomplauncher.sh"
    bash "${SCRIPTS_DIR}/install-streaming-launcher.sh"
    ensure_flatpak_installed
    echo "[+] Instalando Launchers y compatibilidad de gaming..."
    flatpak install -y --noninteractive flathub \
        net.lutris.Lutris \
        com.heroicgameslauncher.hgl \
        io.github.benjamimgois.goverlay \
        com.github.Matoking.protontricks \
        com.vysp3r.ProtonPlus \
        com.github.mtkennerly.ludusavi \
        org.libretro.RetroArch \
        com.steamgriddb.SGDBoop || true
}

install_multimedia_suite() {
    echo -e "\n${BOLD}${CYAN}=== SUITE MULTIMEDIA, STREAMING Y DESCARGAS ===${NC}"
    ensure_flatpak_installed
    echo "[+] Instalando aplicaciones multimedia y streaming de alto rendimiento..."
    flatpak install -y --noninteractive flathub \
        org.videolan.VLC \
        com.stremio.Stremio \
        tv.kodi.Kodi \
        org.qbittorrent.qBittorrent \
        org.jdownloader.JDownloader \
        io.freetubeapp.FreeTube \
        com.github.iwalton3.jellyfin-media-player \
        com.obsproject.Studio \
        io.bassi.Amberol \
        com.spotify.Client || true

    if [ -f "${SCRIPTS_DIR}/configure-qbittorrent.sh" ]; then
        bash "${SCRIPTS_DIR}/configure-qbittorrent.sh"
    fi
}

install_creative_suite() {
    echo -e "\n${BOLD}${CYAN}=== SUITE CREATIVA Y EDICIÓN PROFESIONAL ===${NC}"
    ensure_flatpak_installed
    flatpak install -y --noninteractive flathub \
        fr.handbrake.ghb \
        org.kde.kdenlive \
        org.audacityteam.Audacity \
        org.kde.krita \
        org.gimp.GIMP \
        org.blender.Blender || true
}

install_media_suite() {
    echo -e "\n${BOLD}${CYAN}=== SUITE DE STREAMING, PELÍCULAS, SERIES Y DESCARGAS ===${NC}"
    bash "${SCRIPTS_DIR}/install-media-suite.sh"
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
        -y|--yes|--all|--install-all|--native|-q|--quick|--quick-install) ACTION="native" ;;
        --flatpak-only) ACTION="flatpak_only" ;;
        --dev|--devtools) ACTION="dev_tools" ;;
        --neovim) ACTION="neovim" ;;
        --ai|--ai-tools) ACTION="ai" ;;
        --gaming) ACTION="gaming" ;;
        --gaming-mode) ACTION="gaming_mode" ;;
        --multimedia) ACTION="multimedia" ;;
        --creative) ACTION="creative" ;;
        --vm) ACTION="vm" ;;
        --media|--movies|--streaming-suite) ACTION="media" ;;
        --qbittorrent) ACTION="qbittorrent" ;;
        --stremio) ACTION="stremio" ;;
        --kodi) ACTION="kodi" ;;
        --jdownloader) ACTION="jdownloader" ;;
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
        --openbot) ACTION="openbot" ;;
        --hex) ACTION="hex" ;;
        --craft) ACTION="craft" ;;
        --homebrew) ACTION="homebrew" ;;
        --android) ACTION="android" ;;
        --lsfg) ACTION="lsfg" ;;
        --recomp) ACTION="recomp" ;;
        --streaming) ACTION="streaming" ;;
        --waydroid) ACTION="waydroid" ;;
        --tui|--archinstall) ACTION="tui" ;;
        --desktop-app) ACTION="desktop_app" ;;
        --messaging) ACTION="messaging" ;;
        --whatsapp) ACTION="whatsapp" ;;
        --telegram) ACTION="telegram" ;;
        --communication) ACTION="communication" ;;
        --mysql) ACTION="mysql" ;;
        --1password) ACTION="onepassword" ;;
        --optimize|--tuning) ACTION="optimize" ;;
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

if [ "$ACTION" = "tui" ]; then
    bash "${SCRIPTS_DIR}/tui-installer.sh"
    exit $?
fi

if [ "$ACTION" = "interactive" ]; then
    if [ -f "${SCRIPTS_DIR}/tui-installer.sh" ] && [ -t 0 ]; then
        bash "${SCRIPTS_DIR}/tui-installer.sh"
        exit $?
    fi
    echo -e "${BOLD}¿Cómo deseas instalar tus programas?${NC}"
    echo "  1) Instalar TODO automáticamente (Desarrollo + IA + Gaming + Multimedia + CLI) [Recomendado]"
    echo "  2) Modo 100% Flatpak (Ideal para Bazzite, SteamOS o distros inmutables)"
    echo "  3) Suite de Desarrollo (Neovim, Lazygit, Mise, uv, Bun, Java, GitHub CLI)"
    echo "  4) Suite de Inteligencia Artificial (Ollama, Claude Code, Aider, Antigravity, Grok Bot)"
    echo "  5) Suite de Gaming (Steam, Lutris, Heroic, Prism, RetroArch, ProtonUp-Qt, Goverlay)"
    echo "  6) Suite Multimedia y Creación (OBS Studio, VLC, MPV, HandBrake, Krita, Audacity, GIMP, Blender)"
    echo "  7) Suite de Streaming, Películas y Descargas (Stremio, Kodi, qBittorrent, JDownloader)"
    echo "  8) Solo Comunicación (WhatsApp ZapZap, Telegram, Discord, Vesktop, Slack)"
    echo "  9) Solo Música (Spotify, ncspot [Rust], Strawberry FLAC, Amberol)"
    echo "  10) Solo Terminal rápida (Alacritty) y utilidades CLI"
    echo "  11) Solo Tailscale"
    echo "  12) Simulación (Dry run)"
    echo "  13) Salir"
    echo ""
    read -rp "Selecciona una opción [1-13] (por defecto 1): " choice
    choice=${choice:-1}

    case "$choice" in
        1) ACTION="native" ;;
        2) ACTION="flatpak_only" ;;
        3) ACTION="dev_tools" ;;
        4) ACTION="ai" ;;
        5) ACTION="gaming" ;;
        6) ACTION="multimedia" ;;
        7) ACTION="media" ;;
        8) ACTION="communication" ;;
        9) ACTION="audio" ;;
        10) ACTION="cli" ;;
        11) ACTION="tailscale" ;;
        12) ACTION="dry-run" ;;
        13) echo "Cancelado."; exit 0 ;;
        *) echo "Opción no válida."; exit 1 ;;
    esac
fi

# Mantener sesión de sudo activa durante toda la ejecución
SUDO_KEEPALIVE_PID=""
if [ "$ACTION" != "dry-run" ] && [ "$EUID" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    if ! sudo -n true 2>/dev/null; then
        sudo -v || true
    fi
    ( while true; do sleep 50; sudo -n true 2>/dev/null || exit; done ) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "${SUDO_KEEPALIVE_PID:-}" 2>/dev/null || true' EXIT
fi

run_user_space_parallel_lane() {
    echo -e "\n${BOLD}${CYAN}=== CARRIL PARALELO: HERRAMIENTAS DEV, IA Y GAMING EN SEGUNDO PLANO ===${NC}"
    install_dev_tools &
    install_ai_tools &
    bash "${SCRIPTS_DIR}/install-lsfg-vk.sh" &
    bash "${SCRIPTS_DIR}/install-recomplauncher.sh" &
    bash "${SCRIPTS_DIR}/install-streaming-launcher.sh" &
    bash "${SCRIPTS_DIR}/configure-qbittorrent.sh" &
}

print_install_summary() {
    echo -e "\n${BOLD}${CYAN}=== RESUMEN DE VERIFICACIÓN ===${NC}"
    export PATH="${HOME}/.local/bin:${HOME}/.bun/bin:/usr/games:${PATH}"
    local ok=()
    local miss=()
    for cmd in git gh nvim lazygit mise uv bun ollama claude firefox brave-browser brave-origin code steam gamescope return-to-gaming-mode alacritty tailscale flatpak; do
        if command -v "$cmd" >/dev/null 2>&1; then
            ok+=("$cmd")
        else
            miss+=("$cmd")
        fi
    done
    local fp_count=0
    if command -v flatpak >/dev/null 2>&1; then
        fp_count=$(flatpak list --app 2>/dev/null | wc -l || echo 0)
    fi
    echo -e "  ${GREEN}[✓] Binarios disponibles (${#ok[@]}):${NC} ${ok[*]:-ninguno}"
    echo -e "  ${CYAN}[i] Apps Flatpak instaladas:${NC} ${fp_count}"
    if [ -f /usr/share/wayland-sessions/gamescope-session-steam.desktop ]; then
        echo -e "  ${GREEN}[✓] Sesión Gaming Mode (Wayland):${NC} /usr/share/wayland-sessions/gamescope-session-steam.desktop"
    fi
    if [ ${#miss[@]} -gt 0 ]; then
        echo -e "  ${YELLOW}[i] No detectados como binario nativo (pueden estar en Flatpak o ~/.local/bin):${NC} ${miss[*]}"
    fi
}

case "$ACTION" in
    native)
        install_cli
        ensure_flatpak_installed
        run_user_space_parallel_lane
        install_brave_origin
        install_firefox
        install_vscode "false"
        install_steam "false"
        bash "${SCRIPTS_DIR}/install-gamescope.sh"
        bash "${SCRIPTS_DIR}/install-gaming-mode.sh" || true
        install_tailscale
        install_terminal
        install_craft_suite
        install_1password
        optimize_system
        install_flatpaks
        echo -e "\n${BLUE}[i] Esperando a que finalicen las descargas paralelas de Dev, IA y Gaming...${NC}"
        wait
        print_install_summary
        ;;
    flatpak_only)
        install_cli
        ensure_flatpak_installed
        run_user_space_parallel_lane
        install_firefox
        install_vscode "true"
        install_steam "true"
        bash "${SCRIPTS_DIR}/install-gamescope.sh"
        bash "${SCRIPTS_DIR}/install-gaming-mode.sh" || true
        install_tailscale
        install_terminal
        install_craft_suite
        install_1password
        optimize_system
        install_flatpaks
        echo -e "\n${BLUE}[i] Esperando a que finalicen las descargas paralelas de Dev, IA y Gaming...${NC}"
        wait
        print_install_summary
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
    creative)
        install_creative_suite
        ;;
    vm)
        ensure_flatpak_installed
        flatpak install -y flathub org.virt_manager.virt-manager
        ;;
    media)
        install_media_suite
        ;;
    qbittorrent)
        ensure_flatpak_installed
        flatpak install -y flathub org.qbittorrent.qBittorrent
        bash "${SCRIPTS_DIR}/configure-qbittorrent.sh"
        ;;
    stremio)
        ensure_flatpak_installed
        flatpak install -y flathub com.stremio.Stremio
        ;;
    kodi)
        ensure_flatpak_installed
        flatpak install -y flathub tv.kodi.Kodi
        ;;
    jdownloader)
        ensure_flatpak_installed
        flatpak install -y flathub org.jdownloader.JDownloader
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
    openbot)
        install_openbot
        ;;
    hex)
        install_hex
        ;;
    craft)
        install_craft_suite
        ;;
    homebrew)
        install_homebrew
        ;;
    android)
        install_android_tools
        ;;
    lsfg)
        install_lsfg_vk
        ;;
    recomp)
        install_recomplauncher
        ;;
    streaming)
        install_streaming_launcher
        ;;
    waydroid)
        install_waydroid
        ;;
    mysql)
        install_mysql_workbench
        flatpak install -y flathub org.apache.netbeans
        ;;
    onepassword)
        install_1password
        ;;
    optimize)
        optimize_system
        ;;
    messaging)
        ensure_flatpak_installed
        flatpak install -y flathub com.rtosta.zapzap org.telegram.desktop
        ;;
    whatsapp)
        ensure_flatpak_installed
        flatpak install -y flathub com.rtosta.zapzap
        ;;
    telegram)
        ensure_flatpak_installed
        flatpak install -y flathub org.telegram.desktop
        ;;
    desktop_app)
        mkdir -p "${HOME}/.local/share/applications"
        cat << EOF_APP > "${HOME}/.local/share/applications/linux-setup.desktop"
[Desktop Entry]
Name=Linux-Setup Installer
Comment=Instalador interactivo estilo archinstall para Linux-Setup
Exec=bash -c 'for term in alacritty kitty ghostty gnome-terminal konsole xfce4-terminal xterm; do if command -v "\$term" >/dev/null 2>&1; then exec "\$term" -e bash "${SCRIPT_DIR}/setup.sh" --tui; fi; done'
Icon=system-software-install
Terminal=false
Type=Application
Categories=System;Settings;PackageManager;
EOF_APP
        chmod +x "${HOME}/.local/share/applications/linux-setup.desktop"
        echo -e "${GREEN}[✓] App de escritorio creada en ~/.local/share/applications/linux-setup.desktop${NC}"
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
