#!/usr/bin/env bash
# ==============================================================================
# install-hex.sh - Instalador de Hex (Local Voice Dictation)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"

echo "=== Hex (Local Voice Dictation) ==="

if command -v hex >/dev/null 2>&1 || [ -x "${BIN_DIR}/hex" ]; then
    echo "  [✓] Hex ya está instalado."
    exit 0
fi

TMP_HEX="/tmp/hex-install-$$.sh"
if safe_download "https://anoma.ly/hex/files/install-linux.sh" "${TMP_HEX}" 60; then
    if timeout 180 sh "${TMP_HEX}" >/dev/null 2>&1; then
        echo "  [✓] Hex instalado en ${BIN_DIR}/hex."
    else
        echo "  [!] El instalador de Hex no pudo completar en este entorno."
    fi
    rm -f "${TMP_HEX}"
else
    echo "  [!] No se pudo descargar el instalador de Hex."
fi

if [ "${HAS_SYSTEMD}" = true ]; then
    systemctl --user daemon-reload 2>/dev/null || true
fi
