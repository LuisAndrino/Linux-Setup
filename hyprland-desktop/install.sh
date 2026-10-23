#!/usr/bin/env bash
# ==============================================================================
# install.sh - Despliegue de dotfiles y herramientas de Hyprland (Estilo Omarchy)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_TARGET="${HOME}/.local/bin"
CONFIG_TARGET="${HOME}/.config"

mkdir -p "${BIN_TARGET}" "${CONFIG_TARGET}"

echo "=========================================================="
echo "  Instalador del Entorno Hyprland Ligero (Estilo Omarchy) "
echo "=========================================================="

# 1. Instalar paquetes nativos si estamos en Fedora estándar (con DNF)
if [ ! -f /run/ostree-booted ] && command -v dnf >/dev/null 2>&1; then
    echo "[DNF] Instalando paquetes en Fedora Workstation..."
    sudo dnf copr enable -y ashbuk/Hyprland-Fedora 2>/dev/null || true
    sudo dnf install -y \
        hyprland waybar rofi swaync swaybg grim slurp \
        wl-clipboard brightnessctl playerctl pavucontrol \
        alacritty jetbrains-mono-fonts-all fontawesome-6-free-fonts \
        papirus-icon-theme muParser tomlplusplus 2>/dev/null || true
fi

# 2. Desplegar configuraciones en ~/.config
echo "[+] Desplegando configuraciones limpias en ~/.config..."

mkdir -p "${CONFIG_TARGET}/hypr/themes" \
         "${CONFIG_TARGET}/hypr/plugins" \
         "${CONFIG_TARGET}/waybar" \
         "${CONFIG_TARGET}/rofi" \
         "${CONFIG_TARGET}/alacritty" \
         "${CONFIG_TARGET}/swaync"

# Copiar configuraciones
cp -f "${SCRIPT_DIR}/config/hypr/hyprland.conf" "${CONFIG_TARGET}/hypr/hyprland.conf"
cp -f "${SCRIPT_DIR}/config/waybar/config.jsonc" "${CONFIG_TARGET}/waybar/config.jsonc"
cp -f "${SCRIPT_DIR}/config/waybar/style.css" "${CONFIG_TARGET}/waybar/style.css"
cp -f "${SCRIPT_DIR}/config/rofi/config.rasi" "${CONFIG_TARGET}/rofi/config.rasi"
cp -f "${SCRIPT_DIR}/config/alacritty/alacritty.toml" "${CONFIG_TARGET}/alacritty/alacritty.toml"
cp -f "${SCRIPT_DIR}/config/starship.toml" "${CONFIG_TARGET}/starship.toml"

# 3. Instalar herramientas CLI en ~/.local/bin
echo "[+] Instalando herramientas en ${BIN_TARGET}..."
cp -f "${SCRIPT_DIR}/bin/hypr-theme" "${BIN_TARGET}/"
cp -f "${SCRIPT_DIR}/bin/hypr-plugin" "${BIN_TARGET}/"
cp -f "${SCRIPT_DIR}/bin/agent" "${BIN_TARGET}/"
cp -f "${SCRIPT_DIR}/bin/c" "${BIN_TARGET}/"
chmod +x "${BIN_TARGET}/hypr-theme" "${BIN_TARGET}/hypr-plugin" "${BIN_TARGET}/agent" "${BIN_TARGET}/c"

# 4. Copiar temas base
cp -rf "${SCRIPT_DIR}/themes/"* "${CONFIG_TARGET}/hypr/themes/" 2>/dev/null || true

# 5. Aplicar tema inicial (Tokyo Night)
"${BIN_TARGET}/hypr-theme" tokyo-night 2>/dev/null || true

echo ""
echo "=========================================================="
echo " [✓] ¡Configuraciones de Hyprland desplegadas con éxito!"
echo ""
echo " Atajos clave configurados:"
echo "   Super + Space   -> Menú y buscador rápido (Rofi)"
echo "   Super + Return  -> Terminal acelerada GPU (Alacritty)"
echo "   Super + C       -> Modo Agente AI (Antigravity / Claude)"
echo "   Super + T       -> Cambiar tema en tiempo real"
echo "   Super + Q       -> Cerrar ventana activa"
echo ""
echo " Gestión de temas y extensiones:"
echo "   hypr-theme list              -> Ver temas instalados"
echo "   hypr-theme install <git-url> -> Instalar tema de Omarchy"
echo "   hypr-plugin list             -> Ver extensiones"
echo "   hypr-plugin add <git-url>    -> Instalar extensión/plugin"
echo "=========================================================="
