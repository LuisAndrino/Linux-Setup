#!/usr/bin/env bash
# ==============================================================================
# install-vscode.sh - Instalador de Visual Studio Code (Nativo con opción Flatpak)
# ==============================================================================
set -euo pipefail

PREFER_FLATPAK="${1:-false}"

echo "=========================================================="
echo "          Instalación de Visual Studio Code               "
echo "=========================================================="

if command -v code >/dev/null 2>&1; then
    echo "[✓] VS Code nativo ('code') ya está instalado en el sistema."
    exit 0
elif flatpak info com.visualstudio.code >/dev/null 2>&1; then
    echo "[✓] VS Code (Flatpak) ya está instalado."
    exit 0
fi

if [ "$PREFER_FLATPAK" = "true" ]; then
    echo "[+] Instalando VS Code vía Flatpak..."
    flatpak install -y flathub com.visualstudio.code
    exit 0
fi

# Detectar gestor de paquetes para versión nativa
echo "[+] Configurando e instalando VS Code nativo oficial (Microsoft)..."

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y wget gpg apt-transport-https
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm -f /tmp/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update -y
    sudo apt-get install -y code
    echo "[✓] VS Code nativo instalado vía APT."

elif command -v dnf >/dev/null 2>&1; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update || true
    sudo dnf install -y code || {
        echo "[!] Falló instalación DNF (posible sistema inmutable). Instalando Flatpak..."
        flatpak install -y flathub com.visualstudio.code
    }

elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm code || {
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm visual-studio-code-bin
        elif command -v paru >/dev/null 2>&1; then
            paru -S --needed --noconfirm visual-studio-code-bin
        else
            flatpak install -y flathub com.visualstudio.code
        fi
    }

elif command -v zypper >/dev/null 2>&1; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo zypper addrepo https://packages.microsoft.com/yumrepos/vscode vscode || true
    sudo zypper --non-interactive refresh
    sudo zypper --non-interactive install code

else
    echo "[!] Distribución no soportada de forma nativa. Instalando Flatpak universal..."
    flatpak install -y flathub com.visualstudio.code
fi
