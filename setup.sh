#!/usr/bin/env bash
# ==============================================================================
# setup.sh - Instalador Universal de Software y Entorno para Cualquier Linux
# ==============================================================================
# Autor: Luis (Generado y optimizado por Antigravity)
# Soporta: Ubuntu/Debian, Fedora, Arch/Manjaro, openSUSE, Bazzite, SteamOS, etc.
# ==============================================================================

set -uo pipefail

# Colores para la terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="${SCRIPT_DIR}/packages/flatpak-apps.txt"
CLI_HELPER="${SCRIPT_DIR}/packages/cli-packages.sh"
TAILSCALE_HELPER="${SCRIPT_DIR}/scripts/install-tailscale.sh"

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
    echo "Opciones:"
    echo "  --all             Instala todo (Paquetes CLI + Flatpaks GUI + Tailscale) [Por defecto]"
    echo "  --flatpaks        Instala únicamente las aplicaciones gráficas (Flatpaks)"
    echo "  --cli             Instala únicamente las herramientas CLI del sistema"
    echo "  --tailscale       Instala y configura únicamente Tailscale"
    echo "  --dry-run         Muestra qué se instalaría sin realizar cambios"
    echo "  -h, --help        Muestra esta ayuda"
    echo ""
}

# Comprobar e instalar Flatpak si no existe en el sistema
ensure_flatpak_installed() {
    if ! command -v flatpak >/dev/null 2>&1; then
        echo -e "${YELLOW}[!] Flatpak no está instalado. Instalándolo...${NC}"
        if command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y flatpak
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y flatpak
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm --needed flatpak
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper --non-interactive install flatpak
        else
            echo -e "${RED}[ERROR] No se pudo instalar Flatpak automáticamente. Instálalo manualmente.${NC}"
            return 1
        fi
    fi

    # Asegurar el repositorio Flathub
    echo -e "${BLUE}[+] Verificando repositorio Flathub...${NC}"
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    echo -e "${GREEN}[✓] Flatpak y Flathub listos.${NC}"
}

# Instalación de aplicaciones Flatpak
install_flatpaks() {
    echo -e "\n${BOLD}${CYAN}=== 1. INSTALACIÓN DE APLICACIONES GUI (FLATPAK) ===${NC}"
    ensure_flatpak_installed

    if [ ! -f "${PACKAGES_FILE}" ]; then
        echo -e "${RED}[ERROR] No se encontró el archivo: ${PACKAGES_FILE}${NC}"
        return 1
    fi

    local apps=()
    while IFS= read -r line || [ -n "$line" ]; do
        # Eliminar comentarios y espacios en blanco
        cleaned=$(echo "$line" | sed 's/#.*//' | xargs)
        if [ -n "$cleaned" ]; then
            apps+=("$cleaned")
        fi
    done < "${PACKAGES_FILE}"

    echo -e "${BLUE}[i] Total de aplicaciones a verificar/instalar: ${#apps[@]}${NC}\n"

    local installed_count=0
    local failed_count=0

    for app in "${apps[@]}"; do
        if flatpak info "$app" >/dev/null 2>&1; then
            echo -e "  ${GREEN}[✓ Ya instalado]${NC} $app"
            ((installed_count++))
        else
            echo -e "  ${YELLOW}[+] Instalando:${NC} $app..."
            if flatpak install -y --noninteractive flathub "$app"; then
                echo -e "  ${GREEN}[✓ Completado]${NC} $app"
                ((installed_count++))
            else
                echo -e "  ${RED}[✗ Falló]${NC} $app"
                ((failed_count++))
            fi
        fi
    done

    echo -e "\n${GREEN}[✓] Proceso de Flatpaks terminado: ${installed_count} listos, ${failed_count} con error.${NC}"
}

# Instalación de CLI esencial
install_cli() {
    echo -e "\n${BOLD}${CYAN}=== 2. INSTALACIÓN DE PAQUETES CLI ESENCIALES ===${NC}"
    if [ -f "${CLI_HELPER}" ]; then
        # shellcheck source=/dev/null
        source "${CLI_HELPER}"
        install_essential_cli
    else
        echo -e "${RED}[ERROR] No se encontró ${CLI_HELPER}${NC}"
        return 1
    fi
}

# Instalación de Tailscale
install_tailscale() {
    echo -e "\n${BOLD}${CYAN}=== 3. INSTALACIÓN DE TAILSCALE ===${NC}"
    if [ -f "${TAILSCALE_HELPER}" ]; then
        bash "${TAILSCALE_HELPER}"
    else
        echo -e "${RED}[ERROR] No se encontró ${TAILSCALE_HELPER}${NC}"
        return 1
    fi
}

# Modo simulación
dry_run() {
    echo -e "${YELLOW}${BOLD}--- MODO SIMULACIÓN (DRY-RUN) ---${NC}"
    echo "1. Aplicaciones Flatpak en ${PACKAGES_FILE}:"
    grep -v '^#' "${PACKAGES_FILE}" | grep -v '^$' | while read -r line; do
        echo "   - $line"
    done

    echo ""
    echo "2. Paquetes CLI esenciales a instalar según tu distribución:"
    echo "   - git, gh, curl, wget, jq, ripgrep, tree, rsync"
    echo "   - htop, btop, tmux, zsh, fastfetch, zip/unzip/p7zip"
    echo "   - Compiladores y herramientas base (gcc, make, etc.)"
    echo ""
    echo "3. Tailscale:"
    echo "   - Descarga del script oficial, activación del servicio tailscaled y soporte multi-distro."
}

# Procesar argumentos de línea de comandos
ACTION="interactive"

if [ $# -gt 0 ]; then
    case "$1" in
        --all)
            ACTION="all"
            ;;
        --flatpaks)
            ACTION="flatpaks"
            ;;
        --cli)
            ACTION="cli"
            ;;
        --tailscale)
            ACTION="tailscale"
            ;;
        --dry-run)
            ACTION="dry-run"
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
fi

print_header

if [ "$ACTION" = "dry-run" ]; then
    dry_run
    exit 0
fi

if [ "$ACTION" = "interactive" ]; then
    echo "Elige qué deseas hacer:"
    echo "  1) Instalar TODO (CLI + Flatpaks [VS Code, NetBeans, etc.] + Tailscale) [Recomendado]"
    echo "  2) Instalar solo aplicaciones gráficas (Flatpaks)"
    echo "  3) Instalar solo herramientas CLI esenciales"
    echo "  4) Instalar y configurar solo Tailscale"
    echo "  5) Solo ver qué se instalaría (Dry run)"
    echo "  6) Salir"
    echo ""
    read -rp "Selecciona una opción [1-6] (por defecto 1): " choice
    choice=${choice:-1}

    case "$choice" in
        1) ACTION="all" ;;
        2) ACTION="flatpaks" ;;
        3) ACTION="cli" ;;
        4) ACTION="tailscale" ;;
        5) ACTION="dry-run" ;;
        6) echo "Operación cancelada."; exit 0 ;;
        *) echo "Opción no válida."; exit 1 ;;
    esac
fi

case "$ACTION" in
    all)
        install_cli
        install_flatpaks
        install_tailscale
        ;;
    flatpaks)
        install_flatpaks
        ;;
    cli)
        install_cli
        ;;
    tailscale)
        install_tailscale
        ;;
    dry-run)
        dry_run
        ;;
esac

echo -e "\n${GREEN}${BOLD}======================================================================${NC}"
echo -e "${GREEN}${BOLD}  ¡Configuración completada con éxito!${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo -e "Consejos:"
echo -e " - Si instalaste Tailscale por primera vez, conéctate con: ${CYAN}sudo tailscale up${NC}"
echo -e " - En algunas distros, si instalaste Flatpak por primera vez, puede ser necesario reiniciar sesión para que aparezcan todos los iconos en el menú de aplicaciones."
echo ""
