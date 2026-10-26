#!/usr/bin/env bash
# ==============================================================================
# bootstrap.sh - Instalador Rápido de 1 Línea para Linux Setup
# ==============================================================================
# Uso desde cualquier terminal nueva:
#   curl -sSL https://raw.githubusercontent.com/LuisAndrino/Linux-Setup/main/bootstrap.sh | bash
# O con argumentos (ej. --dev, --yes, --ai, etc.):
#   bash -c "$(curl -sSL https://raw.githubusercontent.com/LuisAndrino/Linux-Setup/main/bootstrap.sh)" -- --yes
# ==============================================================================
set -euo pipefail

REPO_URL="https://github.com/LuisAndrino/Linux-Setup.git"
TARGET_DIR="${HOME}/linux-setup"

echo "=========================================================="
echo "    Instalador Universal de Linux Setup (Luis Andrino)    "
echo "=========================================================="

# 1. Asegurar clonación o descarga del proyecto
if command -v git >/dev/null 2>&1; then
    if [ -d "${TARGET_DIR}/.git" ]; then
        echo "[+] Actualizando repositorio existente en ${TARGET_DIR}..."
        git -C "${TARGET_DIR}" pull --ff-only 2>/dev/null || true
    else
        echo "[+] Clonando repositorio en ${TARGET_DIR}..."
        rm -rf "${TARGET_DIR}"
        git clone "${REPO_URL}" "${TARGET_DIR}"
    fi
else
    echo "[!] Git no está disponible en el sistema base."
    echo "[+] Descargando código fuente mediante curl..."
    mkdir -p "${TARGET_DIR}"
    curl -fsSL "https://github.com/LuisAndrino/Linux-Setup/archive/refs/heads/main.tar.gz" | tar -xz -C "${TARGET_DIR}" --strip-components=1
fi

# 2. Permisos de ejecución
cd "${TARGET_DIR}"
chmod +x setup.sh scripts/*.sh packages/*.sh 2>/dev/null || true

# 3. Ejecutar setup.sh pasando cualquier argumento recibido
if [ $# -gt 0 ]; then
    exec ./setup.sh "$@"
else
    exec ./setup.sh
fi
