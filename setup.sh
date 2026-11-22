#!/usr/bin/env bash
# ==============================================================================
# setup.sh - Instalador Universal Directo para Linux (Sin Menús ni Opciones)
# ==============================================================================
# Compatible con: Ubuntu, Debian, Fedora, Arch Linux, openSUSE, Bazzite, SteamOS
# Uso: ./setup.sh
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
PACKAGES_FILE="${SCRIPT_DIR}/packages/flatpak-apps.txt"

# shellcheck source=/dev/null
source "${SCRIPTS_DIR}/common.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/packages/cli-packages.sh"

echo -e "${CYAN}${BOLD}"
echo "======================================================================"
echo "   Linux-Setup - Instalador Universal Automático (Multi-Distro)"
echo "======================================================================"
echo -e "${NC}"
echo "  Sistema    : ${DISTRO_PRETTY} (${ARCH})"
echo "  Gestor     : ${PKG_MGR} | Inmutable: ${IS_IMMUTABLE} | Contenedor: ${IN_CONTAINER}"
echo ""

# Mantener sesión sudo activa si no somos root
SUDO_KEEPALIVE_PID=""
if [ "${EUID:-$(id -u)}" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    if ! sudo -n true 2>/dev/null; then
        sudo -v || true
    fi
    ( while true; do sleep 50; sudo -n true 2>/dev/null || exit; done ) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "${SUDO_KEEPALIVE_PID:-}" 2>/dev/null || true' EXIT
fi

# ------------------------------------------------------------------------------
# Paso 1/7: Pre-requisitos del sistema, CLI, desarrollo base y Flatpak + Flathub
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}[1/7] Pre-requisitos del sistema, Flatpak y paquetes CLI...${NC}"
install_essential_cli
ensure_flatpak_prereq
ensure_user_path_in_rc

# ------------------------------------------------------------------------------
# Paso 2/7: Apps nativas del sistema (secuenciales para evitar conflictos de lock)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}[2/7] Aplicaciones nativas (Brave, Firefox, VS Code, Steam, Gamescope, Tailscale, 1Password, Alacritty)...${NC}"
for script in \
    install-brave.sh \
    install-firefox.sh \
    install-vscode.sh \
    install-steam.sh \
    install-gamescope.sh \
    install-tailscale.sh \
    install-1password.sh \
    install-terminal.sh; do
    if [ -f "${SCRIPTS_DIR}/${script}" ]; then
        bash "${SCRIPTS_DIR}/${script}" || echo -e "${YELLOW}  [!] ${script} finalizó con advertencias.${NC}"
    fi
done

# ------------------------------------------------------------------------------
# Paso 3/7: Return to Gaming Mode (SteamOS Gamepad UI en Gamescope)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}[3/7] Configurando Return to Gaming Mode...${NC}"
bash "${SCRIPTS_DIR}/install-gaming-mode.sh" || true

# ------------------------------------------------------------------------------
# Paso 4/7: Herramientas de Desarrollo (uv, Bun, Mise, Lazygit, Neovim)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}[4/7] Herramientas de Desarrollo...${NC}"
bash "${SCRIPTS_DIR}/install-dev-tools.sh" || true

# ------------------------------------------------------------------------------
# Paso 5/7: Suite de IA y Utilidades Gaming de Usuario
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}[5/7] Suite de Inteligencia Artificial y Utilidades Gaming...${NC}"
bash "${SCRIPTS_DIR}/install-ai-tools.sh" || true
for script in \
    install-lsfg-vk.sh \
    install-streaming-launcher.sh \
    configure-qbittorrent.sh; do
    if [ -f "${SCRIPTS_DIR}/${script}" ]; then
        bash "${SCRIPTS_DIR}/${script}" || true
    fi
done

# ------------------------------------------------------------------------------
# Paso 6/7: Aplicaciones Flatpak (Flathub + Suite Craft)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}[6/7] Aplicaciones Flatpak (Flathub + Suite Craft)...${NC}"
if [ "${LINUX_SETUP_SKIP_FLATPAKS:-0}" = "1" ]; then
    echo "  [i] Instalación de apps Flatpak omitida por LINUX_SETUP_SKIP_FLATPAKS=1."
elif command -v flatpak >/dev/null 2>&1; then
    flatpak_setup_flathub
    bash "${SCRIPTS_DIR}/install-craft-suite.sh" || true

    if [ -f "${PACKAGES_FILE}" ]; then
        installed_apps="$(flatpak list --app --columns=application 2>/dev/null || true)"
        to_install=()
        while IFS= read -r line || [ -n "$line" ]; do
            app="$(echo "$line" | sed 's/#.*//' | xargs)"
            [ -z "$app" ] && continue

            # Evitar duplicar apps ya instaladas de forma nativa
            if [ "$app" = "com.brave.Browser" ] && (command -v brave-origin >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1); then
                continue
            fi
            if [ "$app" = "org.mozilla.firefox" ] && (command -v firefox >/dev/null 2>&1 || command -v firefox-esr >/dev/null 2>&1); then
                continue
            fi
            if [ "$app" = "com.visualstudio.code" ] && command -v code >/dev/null 2>&1; then
                continue
            fi
            if [ "$app" = "com.valvesoftware.Steam" ] && (command -v steam >/dev/null 2>&1 || [ -x /usr/games/steam ]); then
                continue
            fi
            if [ "$app" = "com.onepassword.OnePassword" ] && command -v 1password >/dev/null 2>&1; then
                continue
            fi
            if [[ $'\n'"${installed_apps}"$'\n' == *$'\n'"${app}"$'\n'* ]]; then
                continue
            fi
            to_install+=("$app")
        done < "${PACKAGES_FILE}"

        if [ ${#to_install[@]} -gt 0 ]; then
            echo "  [+] Instalando ${#to_install[@]} aplicaciones Flatpak desde Flathub..."
            flatpak_install_safe "${to_install[@]}" || true
        else
            echo "  [✓] Todas las aplicaciones Flatpak ya están instaladas."
        fi
    fi
else
    echo "  [!] Flatpak no está instalado; omitiendo aplicaciones Flathub."
fi

# ------------------------------------------------------------------------------
# Paso 7/7: Tema WhiteSur (solo si usa KDE Plasma) y Optimizaciones de Sistema
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}[7/7] Tema KDE WhiteSur (si aplica) y Optimizaciones de Sistema...${NC}"
bash "${SCRIPTS_DIR}/install-whitesur-kde.sh" || true
if [ "${IN_CONTAINER}" = false ]; then
    run_root bash "${SCRIPTS_DIR}/optimize-system.sh" || bash "${SCRIPTS_DIR}/optimize-system.sh" || true
else
    echo "  [i] Contenedor detectado: omitiendo optimizaciones de kernel/sysctl."
fi

# ------------------------------------------------------------------------------
# Resumen de Verificación Final
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}======================================================================${NC}"
echo -e "${BOLD}${CYAN}  RESUMEN DE VERIFICACIÓN FINAL${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"
export PATH="${HOME}/.local/bin:${HOME}/.bun/bin:/usr/games:/usr/local/bin:${PATH}"

ok_list=()
miss_list=()
for cmd in curl git jq rg fzf bat fd zoxide gh java nvim lazygit mise uv bun runjs claude claude-desktop antigravity firefox code steam gamescope return-to-gaming-mode alacritty tailscale op flatpak; do
    if command -v "$cmd" >/dev/null 2>&1; then
        ok_list+=("$cmd")
    else
        miss_list+=("$cmd")
    fi
done

if command -v brave-origin >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1 || command -v brave >/dev/null 2>&1; then
    ok_list+=("brave")
else
    miss_list+=("brave")
fi

fp_count=0
if command -v flatpak >/dev/null 2>&1; then
    fp_count="$(flatpak list --app 2>/dev/null | wc -l || echo 0)"
fi

echo -e "  ${GREEN}[✓] Disponibles (${#ok_list[@]}):${NC} ${ok_list[*]:-ninguno}"
echo -e "  ${CYAN}[i] Apps Flatpak:${NC} ${fp_count}"
if [ -f /usr/share/wayland-sessions/gamescope-session-steam.desktop ]; then
    echo -e "  ${GREEN}[✓] Sesión Wayland Gaming Mode:${NC} /usr/share/wayland-sessions/gamescope-session-steam.desktop"
fi
if [ -d "${HOME}/.local/share/plasma/desktoptheme/WhiteSur" ] || [ -d /usr/share/plasma/desktoptheme/WhiteSur ]; then
    echo -e "  ${GREEN}[✓] Tema KDE WhiteSur:${NC} instalado (Plasma + Iconos + Cursores + GTK + Kvantum)"
fi
if [ ${#miss_list[@]} -gt 0 ]; then
    echo -e "  ${YELLOW}[!] No presentes como binario nativo (${#miss_list[@]}):${NC} ${miss_list[*]}"
fi
echo -e "${GREEN}${BOLD}======================================================================${NC}"
echo -e "${GREEN}${BOLD}  ¡Instalación completada! Reinicia tu terminal para aplicar el PATH.${NC}"
echo -e "${GREEN}${BOLD}======================================================================${NC}"
