#!/usr/bin/env bash
# ==============================================================================
# install-lsfg-vk.sh - Instalador de Lossless Scaling Frame Generation (Vulkan)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Lossless Scaling FG (lsfg-vk) ==="

if [ "${ARCH}" != "x86_64" ]; then
    echo "  [i] lsfg-vk solo está soportado en x86_64 (actual: ${ARCH})."
    exit 0
fi

BIN_DIR="${HOME}/.local/bin"
LIB_DIR="${HOME}/.local/lib"
VULKAN_DIR="${HOME}/.local/share/vulkan/implicit_layer.d"
mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${VULKAN_DIR}" "${HOME}/.local/share/applications" "${HOME}/.local/share/icons/hicolor/256x256/apps"

if [ -f "${BIN_DIR}/lsfg-vk-ui" ] && [ -f "${LIB_DIR}/liblsfg-vk.so" ]; then
    echo "  [✓] lsfg-vk ya está instalado."
    exit 0
fi

LATEST_ZIP_URL="$(safe_fetch "https://api.github.com/repos/PancakeTAS/lsfg-vk/releases/latest" 20 \
    | grep "browser_download_url" \
    | grep -E "lsfg-vk-.*-x86_64\.zip" \
    | cut -d '"' -f 4 \
    | head -n1 || true)"

LATEST_ZIP_URL="${LATEST_ZIP_URL:-https://github.com/PancakeTAS/lsfg-vk/releases/download/v1.0.0/lsfg-vk-1.0.0-x86_64.zip}"

TMP_DIR="/tmp/lsfg-vk-$$"
mkdir -p "${TMP_DIR}"

echo "  [+] Descargando lsfg-vk..."
if safe_download "${LATEST_ZIP_URL}" "${TMP_DIR}/lsfg.zip" 120; then
    unzip -q -o "${TMP_DIR}/lsfg.zip" -d "${TMP_DIR}/out" 2>/dev/null || true
    [ -d "${TMP_DIR}/out/bin" ] && cp -rf "${TMP_DIR}/out/bin/"* "${BIN_DIR}/" && chmod +x "${BIN_DIR}"/lsfg* 2>/dev/null || true
    [ -d "${TMP_DIR}/out/lib" ] && cp -rf "${TMP_DIR}/out/lib/"* "${LIB_DIR}/" || true
    [ -d "${TMP_DIR}/out/share" ] && cp -rf "${TMP_DIR}/out/share/"* "${HOME}/.local/share/" || true

    for json in "${VULKAN_DIR}"/*lsfg*.json "${VULKAN_DIR}"/*LS_frame_generation*.json; do
        if [ -f "$json" ]; then
            sed -i "s|\"library_path\": \".*liblsfg-vk.so\"|\"library_path\": \"${LIB_DIR}/liblsfg-vk.so\"|g" "$json" 2>/dev/null || true
        fi
    done
    echo "  [✓] lsfg-vk instalado."
else
    echo "  [!] No se pudo descargar lsfg-vk."
fi

rm -rf "${TMP_DIR}"
