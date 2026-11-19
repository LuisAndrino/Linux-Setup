#!/usr/bin/env bash
# ==============================================================================
# install-terminal.sh - Instalador multi-distro de Alacritty
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Terminal Alacritty ==="

if command -v alacritty >/dev/null 2>&1; then
    echo "  [✓] Alacritty ya está instalado ($(command -v alacritty))."
    exit 0
fi

case "${PKG_MGR}" in
    apt)    apt_install_list alacritty ;;
    dnf)    dnf_install_list alacritty ;;
    pacman) pacman_install_list alacritty ;;
    zypper) zypper_install_list alacritty ;;
    immutable)
        command -v brew >/dev/null 2>&1 && brew install alacritty 2>/dev/null || true
        ;;
esac

if ! command -v alacritty >/dev/null 2>&1; then
    flatpak_install_safe org.alacritty.Alacritty || true
fi

if command -v alacritty >/dev/null 2>&1 || (command -v flatpak >/dev/null 2>&1 && flatpak info org.alacritty.Alacritty >/dev/null 2>&1); then
    echo "  [✓] Alacritty listo."
fi
