#!/usr/bin/env bash
# ==============================================================================
# install-steam.sh - Instalador multi-distro de Steam
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Steam ==="

if command -v steam >/dev/null 2>&1 || [ -x /usr/games/steam ]; then
    echo "  [✓] Steam ya está instalado."
    exit 0
fi

if command -v flatpak >/dev/null 2>&1 && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    echo "  [✓] Steam ya está instalado vía Flatpak."
    exit 0
fi

if [ "${ARCH}" != "x86_64" ]; then
    echo "  [!] Steam requiere arquitectura x86_64 (actual: ${ARCH}). Omitiendo."
    exit 0
fi

case "${PKG_MGR}" in
    immutable)
        flatpak_install_safe com.valvesoftware.Steam || true
        ;;
    apt)
        echo "  [+] Instalando Steam vía APT (i386 + EULA no interactiva)..."
        if command -v debconf-set-selections >/dev/null 2>&1; then
            echo "steam steam/question select I AGREE" | run_root debconf-set-selections 2>/dev/null || true
            echo "steam steam/license note ''" | run_root debconf-set-selections 2>/dev/null || true
        fi
        if apt_has_candidate steam-installer; then
            apt_install_list steam-installer
        elif apt_has_candidate steam; then
            apt_install_list steam
        fi
        ;;
    dnf)
        echo "  [+] Intentando instalar Steam vía DNF..."
        if ! run_root dnf install -y --setopt=timeout=30 --setopt=retries=3 steam 2>/dev/null; then
            echo "  [i] Steam no está en repos base de Fedora (requiere RPM Fusion). Usando Flatpak..."
            flatpak_install_safe com.valvesoftware.Steam || true
        fi
        ;;
    pacman)
        echo "  [+] Instalando Steam vía Pacman ([multilib])..."
        # Incluir mesa/vulkan para evitar preguntas interactivas de proveedor vulkan-driver
        pacman_install_list vulkan-icd-loader lib32-vulkan-icd-loader mesa lib32-mesa steam
        ;;
    zypper)
        echo "  [+] Instalando Steam vía Zypper..."
        zypper_install_list steam
        ;;
esac

if ! command -v steam >/dev/null 2>&1 && [ ! -x /usr/games/steam ]; then
    flatpak_install_safe com.valvesoftware.Steam || true
fi

if command -v steam >/dev/null 2>&1 || [ -x /usr/games/steam ] || (command -v flatpak >/dev/null 2>&1 && flatpak info com.valvesoftware.Steam >/dev/null 2>&1); then
    echo "  [✓] Steam instalado correctamente."
else
    echo "  [!] No se pudo instalar Steam en este entorno."
fi
