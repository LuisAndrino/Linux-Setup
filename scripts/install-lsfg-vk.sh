#!/usr/bin/env bash
# ==============================================================================
# install-lsfg-vk.sh - Instalador de Lossless Scaling Frame Generation (Vulkan)
# ==============================================================================
# Permite generación de fotogramas (Frame Generation) en juegos Linux / SteamOS
# Repositorio: https://github.com/PancakeTAS/lsfg-vk
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "      Instalación de Lossless Scaling FG (lsfg-vk)        "
echo "=========================================================="

ARCH=$(uname -m)
if [ "${ARCH}" != "x86_64" ]; then
    echo "  [!] lsfg-vk solo está soportado en arquitecturas x86_64 (actual: ${ARCH}). Omitiendo..."
    exit 0
fi

BIN_DIR="${HOME}/.local/bin"
LIB_DIR="${HOME}/.local/lib"
VULKAN_DIR="${HOME}/.local/share/vulkan/implicit_layer.d"
mkdir -p "${BIN_DIR}" "${LIB_DIR}" "${VULKAN_DIR}" "${HOME}/.local/share/applications" "${HOME}/.local/share/icons/hicolor/256x256/apps"

if [ -f "${BIN_DIR}/lsfg-vk-ui" ] && [ -f "${LIB_DIR}/liblsfg-vk.so" ]; then
    echo "  [✓] lsfg-vk ya está instalado en: ${BIN_DIR}/lsfg-vk-ui"
    exit 0
fi

echo "  -> Consultando última versión de lsfg-vk en GitHub Releases..."
LATEST_ZIP_URL=$(curl -s "https://api.github.com/repos/PancakeTAS/lsfg-vk/releases/latest" \
    | grep "browser_download_url" \
    | grep -E "lsfg-vk-.*-x86_64\.zip" \
    | cut -d '"' -f 4 \
    | head -n1 || true)

if [ -z "${LATEST_ZIP_URL}" ]; then
    LATEST_ZIP_URL="https://github.com/PancakeTAS/lsfg-vk/releases/download/v1.0.0/lsfg-vk-1.0.0-x86_64.zip"
fi

TMP_ZIP="/tmp/lsfg-vk-download.zip"
TMP_DIR="/tmp/lsfg-vk-extract"
rm -rf "${TMP_DIR}" "${TMP_ZIP}"
mkdir -p "${TMP_DIR}"

echo "  -> Descargando lsfg-vk desde: ${LATEST_ZIP_URL}..."
if curl -fSL --progress-bar "${LATEST_ZIP_URL}" -o "${TMP_ZIP}"; then
    unzip -q -o "${TMP_ZIP}" -d "${TMP_DIR}"

    # Copiar archivos a ~/.local respetando estructura
    if [ -d "${TMP_DIR}/bin" ]; then
        cp -rf "${TMP_DIR}/bin/"* "${BIN_DIR}/"
        chmod +x "${BIN_DIR}"/lsfg* 2>/dev/null || true
    fi
    if [ -d "${TMP_DIR}/lib" ]; then
        cp -rf "${TMP_DIR}/lib/"* "${LIB_DIR}/"
    fi
    if [ -d "${TMP_DIR}/share" ]; then
        cp -rf "${TMP_DIR}/share/"* "${HOME}/.local/share/"
    fi

    # Asegurar que el JSON apunte a la ruta correcta de la librería
    for json in "${VULKAN_DIR}"/*lsfg*.json "${VULKAN_DIR}"/*LS_frame_generation*.json; do
        if [ -f "$json" ]; then
            sed -i "s|\"library_path\": \".*liblsfg-vk.so\"|\"library_path\": \"${LIB_DIR}/liblsfg-vk.so\"|g" "$json" 2>/dev/null || true
        fi
    done

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
    fi

    echo "  [✓] lsfg-vk instalado con éxito en: ${BIN_DIR}/lsfg-vk-ui"
    echo "  [✓] Capa Vulkan registrada en: ${VULKAN_DIR}"
else
    echo "  [!] No se pudo descargar lsfg-vk automáticamente."
fi

rm -rf "${TMP_DIR}" "${TMP_ZIP}"
