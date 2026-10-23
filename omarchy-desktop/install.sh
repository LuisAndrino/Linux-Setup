#!/usr/bin/env bash
# ==============================================================================
# install.sh - Instalador del Entorno de Escritorio estilo Omarchy
# ==============================================================================
# Instala Hyprland, Waybar, Rofi, Alacritty, SwayNC, Starship, temas dinámicos
# y el Modo de Agentes (con atajos 'c' y 'agent').
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_TARGET="${HOME}/.local/bin"
CONFIG_TARGET="${HOME}/.config"

mkdir -p "${BIN_TARGET}" "${CONFIG_TARGET}"

echo "=========================================================="
echo "    Instalador del Entorno de Escritorio Estilo Omarchy   "
echo "=========================================================="

# 1. Instalar paquetes necesarios según distribución
echo "[+] Comprobando paquetes de escritorio (Hyprland, Waybar, Rofi, etc.)..."

if [ -f /run/ostree-booted ]; then
    echo "[OSTREE] Detectado sistema inmutable (Bazzite/Kinoite). Los paquetes se gestionan mediante rpm-ostree."

elif command -v pacman >/dev/null 2>&1; then
    echo "[PACMAN] Instalando componentes en Arch Linux..."
    sudo pacman -Syu --needed --noconfirm \
        hyprland waybar rofi-wayland swaync alacritty starship \
        ttf-jetbrains-mono-nerd papirus-icon-theme thunar \
        brightnessctl wireplumber xdg-desktop-portal-hyprland 2>/dev/null || true

elif command -v dnf >/dev/null 2>&1; then
    echo "[DNF] Instalando componentes en Fedora..."
    sudo dnf install -y \
        hyprland waybar rofi-wayland swaync alacritty starship \
        papirus-icon-theme thunar brightnessctl wireplumber \
        xdg-desktop-portal-hyprland 2>/dev/null || true

elif command -v apt-get >/dev/null 2>&1; then
    echo "[APT] Instalando componentes en Debian/Ubuntu..."
    sudo apt-get update -y
    sudo apt-get install -y \
        waybar rofi alacritty starship papirus-icon-theme \
        thunar brightnessctl wireplumber 2>/dev/null || true
    echo "Tip: Si tu versión de Ubuntu/Debian no incluye 'hyprland' en repos principales, puedes usar el PPA o repositorio oficial de Hyprland."
fi

# 2. Copiar archivos de configuración (.config)
echo "[+] Desplegando configuraciones estilo Omarchy..."

mkdir -p "${CONFIG_TARGET}/hypr" \
         "${CONFIG_TARGET}/waybar" \
         "${CONFIG_TARGET}/rofi" \
         "${CONFIG_TARGET}/alacritty" \
         "${CONFIG_TARGET}/swaync" \
         "${CONFIG_TARGET}/omarchy"

# Respaldo si ya existen configs previas
for dir in hypr waybar rofi alacritty; do
    if [ -f "${CONFIG_TARGET}/${dir}/${dir}.conf" ] || [ -f "${CONFIG_TARGET}/${dir}/config.jsonc" ]; then
        echo "  [i] Creando respaldo de ${dir} en ~/.config/${dir}.backup..."
        cp -rn "${CONFIG_TARGET}/${dir}" "${CONFIG_TARGET}/${dir}.backup" 2>/dev/null || true
    fi
done

# Copiar configuraciones
cp -f "${SCRIPT_DIR}/config/hypr/hyprland.conf" "${CONFIG_TARGET}/hypr/"
cp -f "${SCRIPT_DIR}/config/waybar/config.jsonc" "${CONFIG_TARGET}/waybar/"
cp -f "${SCRIPT_DIR}/config/waybar/style.css" "${CONFIG_TARGET}/waybar/"
cp -f "${SCRIPT_DIR}/config/rofi/config.rasi" "${CONFIG_TARGET}/rofi/"
cp -f "${SCRIPT_DIR}/config/alacritty/alacritty.toml" "${CONFIG_TARGET}/alacritty/"
cp -f "${SCRIPT_DIR}/config/starship.toml" "${CONFIG_TARGET}/starship.toml"

# 3. Instalar scripts de control ('omarchy-theme', 'agent', 'c')
echo "[+] Instalando comandos CLI y Modo de Agentes en ${BIN_TARGET}..."
cp -f "${SCRIPT_DIR}/bin/omarchy-theme" "${BIN_TARGET}/"
cp -f "${SCRIPT_DIR}/bin/agent" "${BIN_TARGET}/"
cp -f "${SCRIPT_DIR}/bin/c" "${BIN_TARGET}/"
chmod +x "${BIN_TARGET}/omarchy-theme" "${BIN_TARGET}/agent" "${BIN_TARGET}/c"

# Copiar carpeta de temas para que omarchy-theme funcione permanentemente
mkdir -p "${CONFIG_TARGET}/omarchy/themes"
cp -rf "${SCRIPT_DIR}/themes/"* "${CONFIG_TARGET}/omarchy/themes/"

# 4. Aplicar tema inicial (Tokyo Night)
"${BIN_TARGET}/omarchy-theme" tokyo-night

echo ""
echo "=========================================================="
echo " [✓] ¡Entorno estilo Omarchy instalado con éxito!"
echo ""
echo " Atajos clave de Omarchy:"
echo "   Super + Space   -> Menú de aplicaciones (Rofi)"
echo "   Super + Return  -> Terminal rápida (Alacritty)"
echo "   Super + C       -> MODO DE AGENTE (Lanza Antigravity / Claude Code)"
echo "   Super + T       -> Cambiar tema en tiempo real (Tokyo Night / Catppuccin...)"
echo "   Super + Q       -> Cerrar ventana activa"
echo ""
echo " Comandos útiles de terminal:"
echo "   c 'mi tarea'    -> Ejecuta el agente con un prompt"
echo "   omarchy-theme   -> Cambia el tema global (next | tokyo-night | catppuccin...)"
echo ""
echo " Cómo probarlo ahora:"
echo " 1. Modo Ventana Anidada (Sin reiniciar): Escribe 'Hyprland' en tu terminal."
echo " 2. Sesión Completa: Cierra sesión y en tu pantalla de login (SDDM/GDM) elige 'Hyprland'."
echo "=========================================================="
