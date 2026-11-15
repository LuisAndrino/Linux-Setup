#!/usr/bin/env bash
# ==============================================================================
# tui-installer.sh - Selector Interactivo estilo archinstall para Linux-Setup
# ==============================================================================
# Permite:
#  1. Detectar automáticamente ThinkPad T14 Gen 2 AMD / Laptop / Desktop (o preguntar)
#  2. Marcar/desmarcar módulos [x] / [ ]
#  3. Inspeccionar qué paquetes y herramientas incluye cada módulo (i <n>)
#  4. Ejecutar solo lo seleccionado
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_SH="${SCRIPT_DIR}/setup.sh"

BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# Detección de Hardware (ThinkPad T14 Gen 2 AMD / Laptop / Desktop)
# ------------------------------------------------------------------------------
detect_hardware_summary() {
    DMI_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "Desconocido")
    DMI_PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Desconocido")
    DMI_VERSION=$(cat /sys/class/dmi/id/product_version 2>/dev/null || echo "")
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2- | xargs || echo "CPU")
    DISTRO_NAME=$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' || uname -s)

    HW_IS_T14_AMD=false
    HW_IS_LAPTOP=false

    if echo "${DMI_VENDOR} ${DMI_PRODUCT} ${DMI_VERSION}" | grep -qiE "ThinkPad T14 Gen 2|20XK|20XL"; then
        HW_IS_LAPTOP=true
        if echo "${CPU_MODEL}" | grep -qi "AMD"; then
            HW_IS_T14_AMD=true
        fi
    elif compgen -G "/sys/class/power_supply/BAT*" > /dev/null; then
        HW_IS_LAPTOP=true
    fi
}

# ------------------------------------------------------------------------------
# Definición de Módulos (Estilo archinstall)
# ------------------------------------------------------------------------------
MOD_NAMES=(
    "CLI & Terminal Esencial"
    "Suite de Desarrollo (Dev Tools + Neovim)"
    "Suite de Inteligencia Artificial (IA)"
    "Gaming + Steam + Gaming Mode"
    "Comunicación: WhatsApp (ZapZap) + Telegram"
    "Comunicación Completa (+ Discord, Vesktop, Slack)"
    "Streaming, Películas y Descargas (Stremio, Kodi, qBit)"
    "Suite Creativa (OBS, Blender, Kdenlive, GIMP, Krita)"
    "Navegadores y Utilidades (Brave, Firefox, Tailscale, 1Password)"
    "Optimización de Sistema y Rendimiento ThinkPad T14 Gen 2"
)

MOD_FLAGS=(
    "--cli"
    "--dev"
    "--ai"
    "--gaming"
    "--messaging"
    "--communication"
    "--media"
    "--creative"
    "--browsers-utils"
    "--optimize"
)

MOD_DETAILS=(
    "Incluye: git, curl, wget, ripgrep (rg), fd, fzf, zoxide, eza, bat, btop, tmux, fastfetch, jq, alacritty."
    "Incluye: Neovim (Lazy.nvim, Treesitter, Telescope), Lazygit, Mise, uv (Python), Bun, Java, GitHub CLI (gh), VS Code."
    "Incluye: Ollama (LLM local), Claude Code CLI, Aider, Google Antigravity, Grok Bot, OpenBot, Hex (dictado por voz)."
    "Incluye: Steam, Lutris, Heroic Games Launcher, Prism Launcher, ProtonUp-Qt, Goverlay, Gamescope, lsfg-vk y Return to Gaming Mode."
    "Incluye: ZapZap (cliente nativo/Flatpak de WhatsApp) y Telegram Desktop."
    "Incluye: ZapZap (WhatsApp), Telegram Desktop, Discord, Vesktop y Slack."
    "Incluye: Stremio, Kodi, qBittorrent (con plugins de búsqueda), JDownloader 2, VLC, MPV y FreeTube."
    "Incluye: OBS Studio, Kdenlive, Blender, Krita, GIMP, Audacity y HandBrake."
    "Incluye: Brave Origin (repo oficial), Mozilla Firefox, Tailscale VPN y 1Password + CLI."
    "Incluye: sysctl gaming (vm.max_map_count, swappiness=10, split_lock_mitigate=0), TCP BBR, WiFi powersave OFF, y perfil ThinkPad T14 Gen 2 AMD (ACPI platform_profile + CPU EPP performance en AC)."
)

# Estado por defecto: TODAS las suites recomendadas seleccionadas [x]
# (Módulo 5 se deja desmarcado porque el 6 ya incluye Comunicación Completa con WhatsApp + Telegram)
MOD_SELECTED=(1 1 1 1 0 1 1 1 1 1)

detect_hardware_summary

# Si es Desktop o desconocido, preguntar al inicio si es T14 Gen 2 AMD o si quiere perfil laptop
if [ "$HW_IS_T14_AMD" = false ] && [ "$HW_IS_LAPTOP" = false ] && [ -t 0 ]; then
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}=== Detección de Hardware ===${NC}"
    echo -e "  Sistema : ${BOLD}${DISTRO_NAME}${NC}"
    echo -e "  Equipo  : ${DMI_VENDOR} ${DMI_PRODUCT} ${DMI_VERSION}"
    echo -e "  CPU     : ${CPU_MODEL}"
    echo ""
    read -rp "¿Este equipo es una ThinkPad T14 Gen 2 AMD (o laptop) para activar el modo rendimiento en AC? [s/N]: " hw_ans
    if [[ "${hw_ans:-n}" =~ ^[sSyY]$ ]]; then
        HW_IS_T14_AMD=true
        HW_IS_LAPTOP=true
    fi
fi

show_package_detail() {
    local idx="$1"
    echo ""
    echo -e "${CYAN}${BOLD}--- Detalle del Módulo $((idx + 1)): ${MOD_NAMES[$idx]} ---${NC}"
    echo -e "  ${MOD_DETAILS[$idx]}"
    echo -e "  ${DIM}Flag equivalente: ./setup.sh ${MOD_FLAGS[$idx]}${NC}"
    echo ""
    read -rp "Presiona Enter para volver al menú..." _
}

run_selected_modules() {
    local count=0
    local i
    for i in "${!MOD_SELECTED[@]}"; do
        if [ "${MOD_SELECTED[$i]}" -eq 1 ]; then
            count=$((count + 1))
        fi
    done

    if [ "$count" -eq 0 ]; then
        echo -e "${YELLOW}[!] No seleccionaste ningún módulo.${NC}"
        sleep 1
        return
    fi

    echo ""
    echo -e "${GREEN}${BOLD}=== Iniciando instalación de ${count} módulo(s) ===${NC}"
    export NONINTERACTIVE=1

    for i in "${!MOD_SELECTED[@]}"; do
        if [ "${MOD_SELECTED[$i]}" -eq 1 ]; then
            local flag="${MOD_FLAGS[$i]}"
            echo -e "\n${CYAN}${BOLD}>>> Ejecutando: ${MOD_NAMES[$i]} (${flag})${NC}"
            case "$flag" in
                --browsers-utils)
                    bash "${SETUP_SH}" --brave
                    bash "${SETUP_SH}" --firefox
                    bash "${SETUP_SH}" --tailscale
                    bash "${SETUP_SH}" --1password
                    ;;
                *)
                    bash "${SETUP_SH}" "${flag}"
                    ;;
            esac
        fi
    done

    echo -e "\n${GREEN}${BOLD}[✓] Instalación completada.${NC}"
}

while true; do
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}======================================================================${NC}"
    echo -e "${CYAN}${BOLD}  Linux-Setup (Selector Interactivo estilo archinstall)${NC}"
    echo -e "${CYAN}${BOLD}======================================================================${NC}"
    echo -e "  ${BOLD}Distro  :${NC} ${DISTRO_NAME}"
    if [ "$HW_IS_T14_AMD" = true ]; then
        echo -e "  ${BOLD}Hardware:${NC} ${GREEN}ThinkPad T14 Gen 2 AMD / Laptop (Modo AC Performance listo)${NC}"
    elif [ "$HW_IS_LAPTOP" = true ]; then
        echo -e "  ${BOLD}Hardware:${NC} ${GREEN}Laptop detectada (${DMI_VERSION:-$DMI_PRODUCT})${NC}"
    else
        echo -e "  ${BOLD}Hardware:${NC} ${YELLOW}PC de Escritorio (${DMI_PRODUCT})${NC}"
    fi
    echo -e "${DIM}----------------------------------------------------------------------${NC}"
    echo -e "  ${BOLD}Módulos disponibles:${NC}  (Escribe número para marcar, ${CYAN}i <num>${NC} para ver paquetes)"
    echo ""

    for i in "${!MOD_NAMES[@]}"; do
        num=$((i + 1))
        if [ "${MOD_SELECTED[$i]}" -eq 1 ]; then
            mark="${GREEN}[x]${NC}"
        else
            mark="${DIM}[ ]${NC}"
        fi
        printf "  %2d) %b %s\n" "$num" "$mark" "${MOD_NAMES[$i]}"
    done

    echo ""
    echo -e "${DIM}----------------------------------------------------------------------${NC}"
    echo -e "  Comandos: ${CYAN}1-10${NC}=Alternar  |  ${CYAN}i <n>${NC}=Ver paquetes  |  ${CYAN}a${NC}=Todos  |  ${CYAN}n${NC}=Ninguno"
    echo -e "            ${GREEN}${BOLD}go${NC}=Instalar seleccionados  |  ${RED}q${NC}=Salir"
    echo ""
    read -rp "archinstall-setup> " cmd arg

    case "$cmd" in
        go|GO|start|install|s)
            run_selected_modules
            break
            ;;
        q|Q|exit|quit)
            echo "Cancelado."
            exit 0
            ;;
        a|A|all)
            for i in "${!MOD_SELECTED[@]}"; do MOD_SELECTED[$i]=1; done
            ;;
        n|N|none)
            for i in "${!MOD_SELECTED[@]}"; do MOD_SELECTED[$i]=0; done
            ;;
        i|I|info|v|V)
            if [[ "${arg:-}" =~ ^[0-9]+$ ]] && [ "$arg" -ge 1 ] && [ "$arg" -le "${#MOD_NAMES[@]}" ]; then
                show_package_detail "$((arg - 1))"
            else
                echo -e "${YELLOW}Usa: i <número> (ej. i 5)${NC}"
                sleep 1
            fi
            ;;
        *)
            if [[ "$cmd" =~ ^[0-9]+$ ]] && [ "$cmd" -ge 1 ] && [ "$cmd" -le "${#MOD_NAMES[@]}" ]; then
                idx=$((cmd - 1))
                if [ "${MOD_SELECTED[$idx]}" -eq 1 ]; then
                    MOD_SELECTED[$idx]=0
                else
                    MOD_SELECTED[$idx]=1
                fi
            fi
            ;;
    esac
done
