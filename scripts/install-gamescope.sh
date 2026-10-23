#!/usr/bin/env bash
# ==============================================================================
# install-gamescope.sh - Instalador y optimizador de Valve Gamescope
# ==============================================================================
# Gamescope es el micro-compositor de SteamOS para escalado FSR/NIS, HDR,
# control de tasa de refresco, limitador de FPS y aislamiento de resolución.
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          Instalación y Configuración de Gamescope        "
echo "=========================================================="

if command -v gamescope >/dev/null 2>&1; then
    echo "[✓] Gamescope ya está instalado en el sistema ($(command -v gamescope))."
else
    echo "[+] Instalando Gamescope mediante el gestor de paquetes del sistema..."

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y && sudo apt-get install -y gamescope || true
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y gamescope || true
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm gamescope || true
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install gamescope || true
    else
        echo "[!] No se pudo determinar el gestor para instalar Gamescope automáticamente."
    fi
fi

# Optimización de prioridades (cap_sys_nice) recomendada por Valve
if command -v gamescope >/dev/null 2>&1 && command -v setcap >/dev/null 2>&1; then
    GAMESCOPE_BIN="$(command -v gamescope)"
    echo "[+] Asignando permisos 'cap_sys_nice' a Gamescope para máxima suavidad de fotogramas..."
    sudo setcap 'cap_sys_nice=eip' "${GAMESCOPE_BIN}" 2>/dev/null || true
    echo "[✓] Permisos configurados."
fi

echo ""
echo "=========================================================="
echo " [✓] Gamescope listo."
echo ""
echo " Cómo usar Gamescope en Steam (Parámetros de lanzamiento):"
echo "   gamescope -W 1920 -H 1080 -w 1280 -h 720 -F fsr -f -r 60 -- %command%"
echo ""
echo " En Heroic o Lutris:"
echo "   Activa el interruptor 'Gamescope' en los ajustes del juego."
echo "=========================================================="
