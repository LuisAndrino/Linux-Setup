#!/usr/bin/env bash
# ==============================================================================
# install-firefox.sh - Instalador Universal y Optimizado de Mozilla Firefox
# ==============================================================================
# Compatible con: Ubuntu, Debian, Fedora, Arch Linux, openSUSE, Bazzite, SteamOS
# Instala la versión nativa optimizada (o Flatpak oficial en sistemas inmutables)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          Instalación de Mozilla Firefox                  "
echo "=========================================================="

if command -v firefox >/dev/null 2>&1; then
    echo "[✓] Firefox ya está instalado en el sistema ($(firefox --version 2>/dev/null || command -v firefox))."
    exit 0
fi

if flatpak info org.mozilla.firefox >/dev/null 2>&1; then
    echo "[✓] Firefox ya está instalado mediante Flatpak."
    exit 0
fi

# Detectar distro e inmutabilidad
IS_IMMUTABLE=false
DISTRO_ID="unknown"
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    if [ "${ID:-}" = "bazzite" ] || command -v rpm-ostree >/dev/null 2>&1 || [ -f /etc/steamos-release ]; then
        IS_IMMUTABLE=true
    fi
fi

if [ "$IS_IMMUTABLE" = true ]; then
    echo "[+] Sistema inmutable detectado (${DISTRO_ID}). Instalando Firefox Flatpak oficial..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    flatpak install -y --noninteractive flathub org.mozilla.firefox
    echo "[✓] Firefox instalado con éxito vía Flatpak."
    exit 0
fi

case "${DISTRO_ID}" in
    fedora|rhel|centos|rocky|alma)
        echo "[DNF] Instalando Mozilla Firefox nativo..."
        sudo dnf install -y firefox
        ;;

    ubuntu|pop|mint|zorin)
        echo "[APT] Configurando repositorio APT oficial de Mozilla (Firefox nativo sin Snap)..."
        sudo install -d -m 0755 /etc/apt/keyrings
        if curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null; then
            echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
            cat << 'EOF' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
            sudo apt-get update -y
            sudo apt-get install -y firefox || sudo apt-get install -y firefox-esr
        else
            sudo apt-get update -y && sudo apt-get install -y firefox 2>/dev/null || sudo apt-get install -y firefox-esr
        fi
        ;;

    debian|kali)
        echo "[APT] Instalando Firefox en Debian..."
        sudo apt-get update -y && sudo apt-get install -y firefox-esr || sudo apt-get install -y firefox
        ;;

    arch|manjaro|endeavouros|garuda)
        echo "[PACMAN] Instalando Mozilla Firefox..."
        sudo pacman -S --needed --noconfirm firefox
        ;;

    opensuse*|suse|sles)
        echo "[ZYPPER] Instalando Mozilla Firefox..."
        sudo zypper --non-interactive install MozillaFirefox
        ;;

    *)
        echo "[!] Distribución no detectada directamente. Intentando con gestores conocidos..."
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y firefox
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -y && sudo apt-get install -y firefox 2>/dev/null || sudo apt-get install -y firefox-esr
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm firefox
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper --non-interactive install MozillaFirefox
        else
            echo "[+] Fallback a Flatpak..."
            flatpak install -y --noninteractive flathub org.mozilla.firefox
        fi
        ;;
esac

echo ""
echo "=========================================================="
echo " [✓] ¡Mozilla Firefox instalado exitosamente!"
echo "=========================================================="
