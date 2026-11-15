#!/usr/bin/env bash
# ==============================================================================
# install-steam.sh - Instalador de Steam (Nativo con opción Flatpak)
# ==============================================================================
set -euo pipefail

PREFER_FLATPAK="${1:-false}"

echo "=========================================================="
echo "                Instalación de Steam                      "
echo "=========================================================="

if command -v steam >/dev/null 2>&1; then
    echo "[✓] Steam nativo ya está instalado en el sistema ($(command -v steam))."
    exit 0
elif flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    echo "[✓] Steam (Flatpak) ya está instalado."
    exit 0
fi

if [ "$PREFER_FLATPAK" = "true" ]; then
    echo "[+] Instalando Steam vía Flatpak (Flathub)..."
    flatpak install -y flathub com.valvesoftware.Steam
    exit 0
fi

# Detectar sistema inmutable
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ "${ID:-}" = "bazzite" ] || [ "${ID:-}" = "steamos" ]; then
        echo "[✓] En ${ID:-}, Steam ya viene integrado o se recomienda Flatpak si no está presente."
        if ! command -v steam >/dev/null 2>&1; then
            flatpak install -y flathub com.valvesoftware.Steam
        fi
        exit 0
    fi
fi

echo "[+] Intentando instalación de Steam nativo..."

if command -v apt-get >/dev/null 2>&1; then
    echo "[APT] Habilitando arquitectura i386 e instalando Steam..."
    sudo dpkg --add-architecture i386 2>/dev/null || true
    sudo apt-get update -y
    sudo apt-get install -y steam-installer 2>/dev/null || sudo apt-get install -y steam || {
        echo "[!] Falló instalación APT. Instalando Flatpak de Steam..."
        flatpak install -y flathub com.valvesoftware.Steam
    }

elif command -v dnf >/dev/null 2>&1; then
    echo "[DNF] Habilitando RPM Fusion e instalando Steam..."
    sudo dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" 2>/dev/null || true
    sudo dnf install -y steam || {
        echo "[!] Falló instalación DNF. Instalando Flatpak de Steam..."
        flatpak install -y flathub com.valvesoftware.Steam
    }

elif command -v pacman >/dev/null 2>&1; then
    echo "[PACMAN] Instalando Steam..."
    if [ -f /etc/pacman.conf ] && grep -qE '^#\[multilib\]' /etc/pacman.conf; then
        echo "[+] Habilitando repositorio [multilib] en /etc/pacman.conf..."
        sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf 2>/dev/null || true
        sudo pacman -Sy --noconfirm || true
    fi
    sudo pacman -S --needed --noconfirm steam || {
        echo "[!] No se pudo instalar Steam nativo. Instalando vía Flatpak..."
        if ! command -v flatpak >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm flatpak || true
        fi
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        flatpak install -y --noninteractive flathub com.valvesoftware.Steam || true
    }

else
    echo "[!] Distribución no soportada nativamente para Steam. Instalando versión Flatpak..."
    flatpak install -y flathub com.valvesoftware.Steam
fi
