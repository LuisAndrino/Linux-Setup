#!/usr/bin/env bash
# ==============================================================================
# install-gamescope.sh - Instalador y configurador de Valve Gamescope
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Valve Gamescope ==="

if ! command -v gamescope >/dev/null 2>&1; then
    case "${PKG_MGR}" in
        apt)    apt_install_list gamescope ;;
        dnf)    dnf_install_list gamescope ;;
        pacman) pacman_install_list gamescope ;;
        zypper) zypper_install_list gamescope ;;
        immutable) echo "  [i] Sistema inmutable: Gamescope suele estar preinstalado." ;;
    esac
fi

if command -v gamescope >/dev/null 2>&1; then
    GAMESCOPE_BIN="$(command -v gamescope)"
    if command -v setcap >/dev/null 2>&1 && [ "${IN_CONTAINER}" = false ] && [ "${IS_IMMUTABLE}" = false ]; then
        run_root setcap 'cap_sys_nice=eip' "${GAMESCOPE_BIN}" 2>/dev/null || true
    fi
    echo "  [✓] Gamescope disponible (${GAMESCOPE_BIN})."
else
    echo "  [!] Gamescope no está disponible en los repositorios de esta distro."
fi
