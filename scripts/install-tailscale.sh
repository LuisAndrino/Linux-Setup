#!/usr/bin/env bash
# ==============================================================================
# install-tailscale.sh - Instalador multi-distro de Tailscale
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Tailscale ==="

if command -v tailscale >/dev/null 2>&1; then
    echo "  [✓] Tailscale ya está instalado."
else
    case "${PKG_MGR}" in
        pacman)
            pacman_install_list tailscale
            ;;
        immutable)
            echo "  [i] En sistemas inmutables (Bazzite/SteamOS) Tailscale suele venir integrado."
            ;;
        *)
            echo "  [+] Descargando e instalando Tailscale (script oficial)..."
            TMP_TS="/tmp/tailscale-install-$$.sh"
            if safe_download "https://tailscale.com/install.sh" "${TMP_TS}" 60; then
                timeout 240 sh "${TMP_TS}" || echo "  [!] Instalador de Tailscale devolvió error."
                rm -f "${TMP_TS}"
            else
                echo "  [!] No se pudo descargar el script de Tailscale."
            fi
            ;;
    esac
fi

if command -v tailscale >/dev/null 2>&1 && [ "${HAS_SYSTEMD}" = true ]; then
    run_root systemctl enable --now tailscaled >/dev/null 2>&1 || true
    echo "  [✓] Tailscale y servicio tailscaled listos."
elif command -v tailscale >/dev/null 2>&1; then
    echo "  [✓] Tailscale instalado (sin systemd activo)."
fi
