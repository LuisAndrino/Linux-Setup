#!/usr/bin/env bash
# ==============================================================================
# install-brave.sh - Instalador de Brave Origin (Versión oficial nativa)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          Instalación de Brave Origin (Nativo)            "
echo "=========================================================="

# Comprobar si ya está instalado
if command -v brave-origin >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1; then
    echo "[✓] Brave ya está instalado en el sistema:"
    command -v brave-origin 2>/dev/null || command -v brave-browser 2>/dev/null
    exit 0
fi

# Detectar si el sistema es inmutable (Bazzite, SteamOS, Silverblue)
IS_IMMUTABLE=false
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ "${ID:-}" = "bazzite" ] || command -v rpm-ostree >/dev/null 2>&1 || [ -f /etc/steamos-release ]; then
        IS_IMMUTABLE=true
    fi
fi

if [ "$IS_IMMUTABLE" = true ]; then
    echo "[!] Sistema inmutable detectado (${ID:-})."
    echo "    En sistemas como Bazzite/SteamOS, la instalación nativa directa puede requerir layering."
    echo "    Intentando primero el instalador oficial de Brave con FLAVOR=origin..."
fi

echo "[+] Ejecutando script oficial de Brave con FLAVOR=origin..."
if curl -fsSL https://dl.brave.com/install.sh | env FLAVOR=origin sh; then
    echo "[✓] Brave Origin instalado exitosamente mediante el instalador oficial."
    exit 0
else
    echo "[!] El instalador automático de Brave falló o no soportó la distro directamente."
    echo "[+] Intentando configuración manual de repositorios oficiales..."

    if command -v apt-get >/dev/null 2>&1; then
        echo "[APT] Configurando repositorio oficial de Brave..."
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        sudo apt-get update
        sudo apt-get install -y brave-browser || sudo apt-get install -y brave-origin
        echo "[✓] Brave instalado vía APT."

    elif command -v dnf >/dev/null 2>&1 && [ "$IS_IMMUTABLE" = false ]; then
        echo "[DNF] Configurando repositorio oficial de Brave..."
        sudo dnf install -y 'dnf-command(config-manager)' 2>/dev/null || true
        sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo 2>/dev/null || \
        sudo dnf config-manager addrepo --overwrite --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
        sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
        sudo dnf install -y brave-origin || sudo dnf install -y brave-browser
        echo "[✓] Brave instalado vía DNF."

    elif command -v pacman >/dev/null 2>&1; then
        echo "[PACMAN] Instalando Brave en Arch..."
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm brave-bin
        elif command -v paru >/dev/null 2>&1; then
            paru -S --needed --noconfirm brave-bin
        else
            sudo pacman -S --needed --noconfirm brave-browser 2>/dev/null || true
        fi

    else
        echo "[!] No se pudo instalar de forma nativa. Como respaldo seguro, instalando Flatpak..."
        flatpak install -y flathub com.brave.Browser
    fi
fi
