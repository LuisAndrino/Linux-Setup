#!/usr/bin/env bash
# ==============================================================================
# bootstrap.sh - Instalador Universal de 1 Línea para Linux Setup
# ==============================================================================
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/LuisAndrino/Linux-Setup/main/bootstrap.sh | bash
# ==============================================================================
set -euo pipefail

REPO_URL="https://github.com/LuisAndrino/Linux-Setup.git"
ARCHIVE_URL="https://github.com/LuisAndrino/Linux-Setup/archive/refs/heads/main.tar.gz"
TARGET_DIR="${HOME}/linux-setup"

echo "=========================================================="
echo "    Linux Setup - Instalador Universal (Luis Andrino)     "
echo "=========================================================="

if command -v git >/dev/null 2>&1; then
    if [ -d "${TARGET_DIR}/.git" ]; then
        echo "[+] Actualizando repositorio en ${TARGET_DIR}..."
        git -C "${TARGET_DIR}" pull --ff-only 2>/dev/null || true
    else
        echo "[+] Clonando repositorio en ${TARGET_DIR}..."
        rm -rf "${TARGET_DIR}"
        git clone --depth 1 "${REPO_URL}" "${TARGET_DIR}"
    fi
elif command -v curl >/dev/null 2>&1; then
    echo "[+] Descargando código fuente con curl..."
    rm -rf "${TARGET_DIR}"
    mkdir -p "${TARGET_DIR}"
    curl -fsSL --connect-timeout 15 --max-time 60 "${ARCHIVE_URL}" | tar -xz -C "${TARGET_DIR}" --strip-components=1
elif command -v wget >/dev/null 2>&1; then
    echo "[+] Descargando código fuente con wget..."
    rm -rf "${TARGET_DIR}"
    mkdir -p "${TARGET_DIR}"
    wget -qO- --timeout=30 "${ARCHIVE_URL}" | tar -xz -C "${TARGET_DIR}" --strip-components=1
else
    echo "[!] Error: necesitas git, curl o wget instalado para descargar Linux-Setup." >&2
    exit 1
fi

cd "${TARGET_DIR}"
chmod +x setup.sh quick-install.sh bootstrap.sh scripts/*.sh packages/*.sh 2>/dev/null || true

exec bash "${TARGET_DIR}/setup.sh"
