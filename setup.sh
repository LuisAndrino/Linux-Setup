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
    echo "Opciones principales:"
    echo "  --native          Instala programas en versión NATIVA (Brave Origin, VS Code nativo,"
    echo "                    Steam, Tailscale, Grok Bot, Craft Suite, CLI + Flatpaks complementarios) [Recomendado]"
    echo "  --flatpak-only    Instala todo exclusivamente mediante Flatpak (Ideal para Bazzite/SteamOS)"
    echo "  --cli             Instala solo herramientas de terminal y paquetes esenciales del sistema"
    echo "  --brave           Instala solo Brave Origin (repositorio nativo oficial)"
    echo "  --vscode          Instala solo Visual Studio Code (nativo con fallback a Flatpak)"
    echo "  --steam           Instala solo Steam"
    echo "  --tailscale       Instala y configura solo Tailscale"
    echo "  --grokbot         Instala y configura solo Grok Bot (AppImage)"
    echo "  --craft           Instala ArtCraft Launcher y la suite Craft (GridCraft, DeckCraft...)"
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
        # Evitar duplicados si el usuario instaló la versión nativa de Brave, VS Code o Steam
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
    echo -e "\n${BOLD}${CYAN}=== HERRAMIENTAS CLI ESENCIALES ===${NC}"
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

install_grokbot() {
    echo -e "\n${BOLD}${CYAN}=== GROK BOT ===${NC}"
    bash "${SCRIPTS_DIR}/install-grokbot.sh"
}

install_craft_suite() {
    echo -e "\n${BOLD}${CYAN}=== SUITE CRAFT (ARTCRAFT, GRIDCRAFT, DECKCRAFT...) ===${NC}"
    bash "${SCRIPTS_DIR}/install-craft-suite.sh"
}

dry_run() {
    echo -e "${YELLOW}${BOLD}--- MODO SIMULACIÓN (DRY-RUN) ---${NC}"
    echo "1. Programas Nativos / Especiales:"
    echo "   - Brave: Se instalará Brave Origin mediante script oficial (FLAVOR=origin)."
    echo "   - VS Code: Se configurará el repositorio oficial de Microsoft (APT/DNF/Pacman)."
    echo "   - Steam: Se instalará el paquete nativo de la distro o Steam Flatpak."
    echo "   - Tailscale: Script oficial universal + activación de systemd."
    echo "   - Grok Bot: Integración de AppImage en ~/.local/share/grok-bot + .desktop."
    echo "   - Suite Craft: ArtCraft Launcher (bundle) para GridCraft, DeckCraft, WordCraft y PdfCraft."
    echo ""
    echo "2. Herramientas CLI del sistema:"
    echo "   - git, gh, curl, wget, jq, ripgrep, tree, rsync, htop, btop, tmux, zsh, build tools."
    echo ""
    echo "3. Aplicaciones Flatpak complementarias (Flathub):"
    grep -v '^#' "${PACKAGES_FILE}" | grep -v '^$' | while read -r line; do
        echo "   - $line"
    done
}

ACTION="interactive"

if [ $# -gt 0 ]; then
    case "$1" in
        --native|--all) ACTION="native" ;;
        --flatpak-only) ACTION="flatpak_only" ;;
        --cli) ACTION="cli" ;;
        --brave) ACTION="brave" ;;
        --vscode) ACTION="vscode" ;;
        --steam) ACTION="steam" ;;
        --tailscale) ACTION="tailscale" ;;
        --grokbot) ACTION="grokbot" ;;
        --craft) ACTION="craft" ;;
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
    echo "  1) Modo Híbrido / Nativo (Recomendado para distros tradicionales):"
    echo "     - Brave Origin nativo, VS Code nativo, Steam, Tailscale,"
    echo "     - Grok Bot (AppImage), Suite Craft (ArtCraft/GridCraft),"
    echo "     - Herramientas CLI + Flatpaks complementarios (1Password, NetBeans, Spotify, VLC...)"
    echo ""
    echo "  2) Modo 100% Flatpak (Ideal para Bazzite, SteamOS o sistemas inmutables)"
    echo "  3) Solo Brave Origin (Nativo)"
    echo "  4) Solo VS Code y NetBeans"
    echo "  5) Solo Steam, Grok Bot y Suite Craft"
    echo "  6) Solo Tailscale"
    echo "  7) Solo herramientas de terminal (CLI)"
    echo "  8) Simulación (Dry run)"
    echo "  9) Salir"
    echo ""
    read -rp "Selecciona una opción [1-9] (por defecto 1): " choice
    choice=${choice:-1}

    case "$choice" in
        1) ACTION="native" ;;
        2) ACTION="flatpak_only" ;;
        3) ACTION="brave" ;;
        4) ACTION="dev_tools" ;;
        5) ACTION="custom_apps" ;;
        6) ACTION="tailscale" ;;
        7) ACTION="cli" ;;
        8) ACTION="dry-run" ;;
        9) echo "Cancelado."; exit 0 ;;
        *) echo "Opción no válida."; exit 1 ;;
    esac
fi

case "$ACTION" in
    native)
        install_cli
        install_brave_origin
        install_vscode "false"
        install_steam "false"
        install_tailscale
        install_grokbot
        install_craft_suite
        install_flatpaks
        ;;
    flatpak_only)
        install_cli
        install_vscode "true"
        install_steam "true"
        install_tailscale
        install_grokbot
        install_craft_suite
        install_flatpaks
        ;;
    brave)
        install_brave_origin
        ;;
    dev_tools)
        install_vscode "false"
        flatpak install -y flathub org.apache.netbeans
        ;;
    custom_apps)
        install_steam "false"
        install_grokbot
        install_craft_suite
        ;;
    tailscale)
        install_tailscale
        ;;
    cli)
        install_cli
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
echo -e " - Si instalaste aplicaciones nuevas, puedes verlas en tu menú de aplicaciones."
echo ""
