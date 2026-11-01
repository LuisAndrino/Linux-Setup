#!/usr/bin/env bash
# ==============================================================================
# install-android-tools.sh - Instalador de Android Platform Tools (adb & fastboot)
# ==============================================================================
# Multi-distro: Debian/Ubuntu, Fedora, Arch Linux, openSUSE, Bazzite/SteamOS
# ==============================================================================
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"

echo "=========================================================="
echo "    Instalación de Android Platform Tools (adb, fastboot) "
echo "=========================================================="

if command -v adb >/dev/null 2>&1 && command -v fastboot >/dev/null 2>&1; then
    echo "  [✓] adb y fastboot ya están disponibles en tu sistema:"
    echo "      adb: $(command -v adb)"
    echo "      fastboot: $(command -v fastboot)"
    exit 0
fi

INSTALLED=false

# 1. Intentar con Homebrew si está disponible (ideal para Bazzite/SteamOS)
if command -v brew >/dev/null 2>&1; then
    echo "  -> Instalando via Homebrew (android-platform-tools)..."
    if brew install --cask android-platform-tools 2>/dev/null; then
        INSTALLED=true
    fi
fi

# 2. Intentar gestor nativo si no se instaló con Homebrew
if [ "${INSTALLED}" = false ] && command -v sudo >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        echo "  -> Instalando android-tools vía DNF..."
        sudo dnf install -y android-tools 2>/dev/null && INSTALLED=true || true
    elif command -v apt >/dev/null 2>&1; then
        echo "  -> Instalando adb y fastboot vía APT..."
        sudo apt update -y 2>/dev/null || true
        sudo apt install -y adb fastboot 2>/dev/null && INSTALLED=true || true
    elif command -v pacman >/dev/null 2>&1; then
        echo "  -> Instalando android-tools vía Pacman..."
        sudo pacman -S --needed --noconfirm android-tools 2>/dev/null && INSTALLED=true || true
    elif command -v zypper >/dev/null 2>&1; then
        echo "  -> Instalando android-tools vía Zypper..."
        sudo zypper --non-interactive install android-tools 2>/dev/null && INSTALLED=true || true
    fi
fi

# 3. Fallback directo: Descargar binarios oficiales de Google
if [ "${INSTALLED}" = false ]; then
    echo "  -> Descargando Google Android SDK Platform-Tools oficiales..."
    TMP_ZIP="/tmp/platform-tools-latest-linux.zip"
    curl -fsSL "https://dl.google.com/android/repository/platform-tools-latest-linux.zip" -o "${TMP_ZIP}" 2>/dev/null || true
    if [ -f "${TMP_ZIP}" ]; then
        TARGET_DIR="${HOME}/.local/share/android-platform-tools"
        mkdir -p "${TARGET_DIR}"
        unzip -q -o "${TMP_ZIP}" -d "${TARGET_DIR}" 2>/dev/null || true
        rm -f "${TMP_ZIP}"

        if [ -f "${TARGET_DIR}/platform-tools/adb" ]; then
            ln -sf "${TARGET_DIR}/platform-tools/adb" "${BIN_DIR}/adb"
            ln -sf "${TARGET_DIR}/platform-tools/fastboot" "${BIN_DIR}/fastboot"
            chmod +x "${BIN_DIR}/adb" "${BIN_DIR}/fastboot"
            INSTALLED=true
        fi
    fi
fi

if command -v adb >/dev/null 2>&1; then
    echo "  [✓] Android Tools instaladas con éxito ($(adb version 2>/dev/null | head -n1))."
else
    echo "  [!] No se pudo completar la instalación automática de adb/fastboot."
fi
