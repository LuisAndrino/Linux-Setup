#!/usr/bin/env bash
# ==============================================================================
# install-waydroid.sh - Instalador y configurador de Waydroid (Emulador Android)
# ==============================================================================
# Waydroid ejecuta un sistema Android completo (LineageOS) dentro de un
# contenedor LXC con aceleración de GPU nativa y renderizado directo en Wayland.
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          Instalación de Waydroid (Android en Linux)      "
echo "=========================================================="

# 1. Comprobar si ya está instalado
if command -v waydroid >/dev/null 2>&1; then
    echo "[✓] Waydroid ya está instalado en el sistema ($(command -v waydroid))."
else
    echo "[+] Instalando Waydroid mediante el gestor del sistema..."

    if command -v apt-get >/dev/null 2>&1; then
        echo "[APT] Configurando repositorio oficial de Waydroid..."
        curl -fsSL https://repo.waydro.id | sudo bash
        sudo apt-get update -y
        sudo apt-get install -y waydroid scrcpy adb || true

    elif command -v dnf >/dev/null 2>&1; then
        echo "[DNF] Instalando Waydroid..."
        sudo dnf install -y waydroid scrcpy android-tools || true

    elif command -v pacman >/dev/null 2>&1; then
        echo "[PACMAN] Instalando Waydroid..."
        sudo pacman -S --needed --noconfirm waydroid scrcpy android-tools || true

    elif command -v zypper >/dev/null 2>&1; then
        echo "[ZYPPER] Instalando Waydroid..."
        sudo zypper --non-interactive install waydroid scrcpy android-tools || true

    else
        echo "[!] No se pudo instalar automáticamente. Consulta la guía oficial en: https://waydro.id"
    fi
fi

# 2. Habilitar servicio del contenedor de Waydroid en systemd
if command -v systemctl >/dev/null 2>&1; then
    echo "[+] Habilitando servicio del contenedor de Waydroid (waydroid-container)..."
    sudo systemctl enable --now waydroid-container 2>/dev/null || true
    echo "[✓] Servicio waydroid-container habilitado."
fi

echo ""
echo "=========================================================="
echo " [✓] Waydroid instalado y servicio activado."
echo ""
echo " Pasos para inicializar Android por primera vez:"
echo " 1. Para inicializar con Google Play Store (GAPPS):"
echo "      sudo waydroid init -s GAPPS"
echo "    O versión ligera sin Google Play (Vanilla):"
echo "      sudo waydroid init"
echo ""
echo " 2. Para iniciar la sesión gráfica de Android:"
echo "      waydroid session start"
echo "    O abre 'Waydroid' directamente desde tu menú de aplicaciones."
echo ""
echo " Tip para juegos y apps ARM (TikTok, Clash, WhatsApp APK, etc.):"
echo "   Puedes instalar traducción ARM (libndk/libhoudini) con este script:"
echo "   git clone https://github.com/casualsnek/waydroid_script"
echo "   cd waydroid_script && python3 main.py install libndk"
echo "=========================================================="
