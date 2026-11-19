#!/usr/bin/env bash
# ==============================================================================
# install-firefox.sh - Instalador multi-distro de Mozilla Firefox
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Mozilla Firefox ==="

if command -v firefox >/dev/null 2>&1 || command -v firefox-esr >/dev/null 2>&1; then
    echo "  [✓] Firefox ya está instalado."
    exit 0
fi

if command -v flatpak >/dev/null 2>&1 && flatpak info org.mozilla.firefox >/dev/null 2>&1; then
    echo "  [✓] Firefox ya está instalado vía Flatpak."
    exit 0
fi

case "${PKG_MGR}" in
    immutable)
        flatpak_install_safe org.mozilla.firefox || true
        ;;
    apt)
        if [[ "${DISTRO_ID}" == "ubuntu" ]] || [[ "${DISTRO_ID_LIKE}" == *ubuntu* ]]; then
            echo "  [+] Configurando repositorio APT oficial de Mozilla (sin Snap)..."
            run_root install -d -m 0755 /etc/apt/keyrings
            if safe_download "https://packages.mozilla.org/apt/repo-signing-key.gpg" "/tmp/mozilla-key.asc" 30; then
                run_root install -m 0644 /tmp/mozilla-key.asc /etc/apt/keyrings/packages.mozilla.org.asc
                rm -f /tmp/mozilla-key.asc
                echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | \
                    run_root tee /etc/apt/sources.list.d/mozilla.list >/dev/null
                run_root tee /etc/apt/preferences.d/mozilla >/dev/null << 'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
                apt_update_safe
                apt_install_list firefox
            else
                apt_install_list firefox-esr
            fi
        else
            echo "  [+] Instalando Firefox (Debian APT)..."
            if apt_has_candidate firefox-esr; then
                apt_install_list firefox-esr
            else
                apt_install_list firefox
            fi
        fi
        ;;
    dnf)
        dnf_install_list firefox
        ;;
    pacman)
        pacman_install_list firefox
        ;;
    zypper)
        zypper_install_list MozillaFirefox
        ;;
esac

if ! command -v firefox >/dev/null 2>&1 && ! command -v firefox-esr >/dev/null 2>&1; then
    flatpak_install_safe org.mozilla.firefox || true
fi

if command -v firefox >/dev/null 2>&1 || command -v firefox-esr >/dev/null 2>&1 || (command -v flatpak >/dev/null 2>&1 && flatpak info org.mozilla.firefox >/dev/null 2>&1); then
    echo "  [✓] Firefox instalado correctamente."
else
    echo "  [!] No se pudo instalar Firefox en este entorno."
fi
