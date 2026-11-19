#!/usr/bin/env bash
# ==============================================================================
# install-vscode.sh - Instalador multi-distro de Visual Studio Code
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Visual Studio Code ==="

if command -v code >/dev/null 2>&1; then
    echo "  [✓] VS Code ya está instalado ($(command -v code))."
    exit 0
fi

case "${PKG_MGR}" in
    immutable)
        flatpak_install_safe com.visualstudio.code || true
        ;;
    apt)
        echo "  [+] Configurando repositorio oficial de Microsoft VS Code (APT)..."
        run_root install -d -m 0755 /etc/apt/keyrings
        if safe_download "https://packages.microsoft.com/keys/microsoft.asc" "/tmp/microsoft.asc" 30; then
            gpg --dearmor --batch --yes -o /tmp/packages.microsoft.gpg /tmp/microsoft.asc
            run_root install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
            rm -f /tmp/microsoft.asc /tmp/packages.microsoft.gpg
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
                run_root tee /etc/apt/sources.list.d/vscode.list >/dev/null
            apt_update_safe
            apt_install_list code
        fi
        ;;
    dnf)
        echo "  [+] Configurando repositorio oficial de Microsoft VS Code (DNF)..."
        run_root rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
        run_root tee /etc/yum.repos.d/vscode.repo >/dev/null << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        dnf_install_list code
        ;;
    pacman)
        echo "  [+] Instalando VS Code en Arch..."
        if command -v paru >/dev/null 2>&1 && [ "${EUID:-$(id -u)}" -ne 0 ]; then
            paru -S --needed --noconfirm visual-studio-code-bin || pacman_install_list code
        elif command -v yay >/dev/null 2>&1 && [ "${EUID:-$(id -u)}" -ne 0 ]; then
            yay -S --needed --noconfirm visual-studio-code-bin || pacman_install_list code
        else
            pacman_install_list code
        fi
        ;;
    zypper)
        echo "  [+] Configurando repositorio oficial de Microsoft VS Code (Zypper)..."
        run_root rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
        run_root tee /etc/zypp/repos.d/vscode.repo >/dev/null << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        run_root zypper --non-interactive --gpg-auto-import-keys refresh || true
        zypper_install_list code
        ;;
esac

if ! command -v code >/dev/null 2>&1; then
    flatpak_install_safe com.visualstudio.code || true
fi

if command -v code >/dev/null 2>&1 || (command -v flatpak >/dev/null 2>&1 && flatpak info com.visualstudio.code >/dev/null 2>&1); then
    echo "  [✓] VS Code instalado correctamente."
else
    echo "  [!] No se pudo instalar VS Code en este entorno."
fi
