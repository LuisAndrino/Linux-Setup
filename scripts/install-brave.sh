#!/usr/bin/env bash
# ==============================================================================
# install-brave.sh - Instalador multi-distro de Brave Origin / Brave Browser
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Brave Origin ==="

if command -v brave-origin >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1 || command -v brave >/dev/null 2>&1; then
    echo "  [✓] Brave ya está instalado."
    exit 0
fi

case "${PKG_MGR}" in
    apt)
        echo "  [+] Configurando repositorio oficial de Brave (APT)..."
        run_root install -d -m 0755 /usr/share/keyrings
        if safe_download "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" "/tmp/brave-keyring.gpg" 30; then
            run_root install -m 0644 /tmp/brave-keyring.gpg /usr/share/keyrings/brave-browser-archive-keyring.gpg
            rm -f /tmp/brave-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=${DEB_ARCH}] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
                run_root tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
            apt_update_safe
            if apt_has_candidate brave-origin; then
                apt_install_list brave-origin
            else
                apt_install_list brave-browser
            fi
        fi
        ;;
    dnf)
        echo "  [+] Configurando repositorio oficial de Brave (DNF)..."
        run_root rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>/dev/null || true
        if safe_download "https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo" "/tmp/brave-browser.repo" 30; then
            run_root install -m 0644 /tmp/brave-browser.repo /etc/yum.repos.d/brave-browser.repo
            rm -f /tmp/brave-browser.repo
            if ! run_root dnf install -y --setopt=timeout=30 --setopt=retries=3 brave-origin 2>/dev/null; then
                run_root dnf install -y --setopt=timeout=30 --setopt=retries=3 brave-browser || true
            fi
        fi
        ;;
    pacman)
        echo "  [+] Instalando Brave en Arch..."
        if pacman -Si brave-origin >/dev/null 2>&1; then
            run_root pacman -S --needed --noconfirm brave-origin || true
        elif pacman -Si brave-browser >/dev/null 2>&1; then
            run_root pacman -S --needed --noconfirm brave-browser || true
        elif command -v paru >/dev/null 2>&1 && [ "${EUID:-$(id -u)}" -ne 0 ]; then
            paru -S --needed --noconfirm brave-origin-bin || paru -S --needed --noconfirm brave-bin || true
        elif command -v yay >/dev/null 2>&1 && [ "${EUID:-$(id -u)}" -ne 0 ]; then
            yay -S --needed --noconfirm brave-origin-bin || yay -S --needed --noconfirm brave-bin || true
        fi
        ;;
    zypper)
        echo "  [+] Configurando repositorio oficial de Brave (Zypper)..."
        run_root rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>/dev/null || true
        run_root zypper --non-interactive --gpg-auto-import-keys addrepo -f https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo 2>/dev/null || true
        run_root zypper --non-interactive --gpg-auto-import-keys refresh || true
        if ! run_root zypper --non-interactive install --no-confirm brave-origin 2>/dev/null; then
            run_root zypper --non-interactive install --no-confirm brave-browser || true
        fi
        ;;
esac

if ! command -v brave-origin >/dev/null 2>&1 && ! command -v brave-browser >/dev/null 2>&1 && ! command -v brave >/dev/null 2>&1; then
    echo "  [+] Respaldo universal: instalando Brave vía Flatpak..."
    flatpak_install_safe com.brave.Browser || true
fi

if command -v brave-origin >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1 || command -v brave >/dev/null 2>&1 || flatpak info com.brave.Browser >/dev/null 2>&1; then
    echo "  [✓] Brave instalado correctamente."
else
    echo "  [!] No se pudo instalar Brave en este entorno."
fi
