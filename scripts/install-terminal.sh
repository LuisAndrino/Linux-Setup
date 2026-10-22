#!/usr/bin/env bash
# ==============================================================================
# install-terminal.sh - Instalador de terminal acelerada por GPU (Estilo Omarchy)
# ==============================================================================
# Omarchy utiliza Alacritty y Ghostty como terminales por defecto por su
# extrema velocidad y renderizado por GPU.
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "    Instalación de Terminal Rápida (Alacritty / Ghostty)  "
echo "=========================================================="

if command -v alacritty >/dev/null 2>&1; then
    echo "[✓] Alacritty ya está instalado ($(command -v alacritty))."
else
    echo "[+] Instalando Alacritty (Terminal ultra-rápida acelerada por GPU)..."

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y && sudo apt-get install -y alacritty
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y alacritty
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm alacritty
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install alacritty
    elif command -v brew >/dev/null 2>&1; then
        brew install alacritty
    else
        echo "[+] Gestor nativo no soportado, instalando Alacritty vía Flatpak..."
        flatpak install -y flathub org.alacritty.Alacritty
    fi
fi

# Intentar instalar Ghostty si está disponible (la nueva terminal adoptada por Omarchy)
echo ""
echo "[+] Comprobando disponibilidad de Ghostty..."
if command -v ghostty >/dev/null 2>&1; then
    echo "[✓] Ghostty ya está instalado en el sistema."
else
    if command -v pacman >/dev/null 2>&1 && command -v yay >/dev/null 2>&1; then
        echo "[+] Instalando Ghostty desde AUR en Arch..."
        yay -S --needed --noconfirm ghostty-bin 2>/dev/null || true
    fi
fi

echo ""
echo "=========================================================="
echo " [✓] Terminal rápida lista para usar: alacritty"
echo " Omarchy combina esta terminal con 'tmux' para paneles y pestañas."
echo "=========================================================="
