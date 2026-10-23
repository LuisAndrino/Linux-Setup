#!/usr/bin/env bash
# ==============================================================================
# rollback-bazzite.sh - Limpieza y reversión completa del entorno en Bazzite
# ==============================================================================
# 1. Elimina todos los binarios, librerías y sesiones de Hyprland en /usr/local
# 2. Elimina configuraciones de SDDM y restaura el servicio de autologin de Bazzite
# 3. Elimina repositorios Copr de Hyprland en /etc/yum.repos.d/
# 4. Ejecuta rpm-ostree reset para revertir las capas añadidas a la imagen base
# ==============================================================================
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[!] Este script requiere permisos de administrador para restaurar el sistema."
    echo "    Por favor ejecútalo con: sudo $0"
    exit 1
fi

echo "=========================================================="
echo "    Iniciando Rollback y Restauración de Bazzite OS       "
echo "=========================================================="

# 1. Limpiar /usr/local
echo "[1/4] Eliminando binarios y archivos de Hyprland en /usr/local..."
rm -f /usr/local/bin/hyprctl \
      /usr/local/bin/hyprland \
      /usr/local/bin/Hyprland \
      /usr/local/bin/hyprpm \
      /usr/local/bin/start-hyprland \
      /usr/local/bin/start-hyprland-session
rm -rf /usr/local/libexec/hyprland
rm -f /usr/local/share/wayland-sessions/hyprland.desktop
rm -rf /usr/local/share/hypr
rm -f /usr/local/share/xdg-desktop-portal/hyprland-portals.conf
echo "  [✓] /usr/local restaurado."

# 2. Restaurar SDDM y bazzite-autologin
echo "[2/4] Restaurando configuración original de SDDM y login de Bazzite..."
rm -f /etc/sddm.conf.d/zz-zzz-manual-session.conf
systemctl unmask bazzite-autologin.service 2>/dev/null || true
systemctl enable bazzite-autologin.service 2>/dev/null || true

# Configurar desktop como modo por defecto limpio
steamosctl set-default-login-mode desktop 2>/dev/null || true
echo "  [✓] SDDM y servicio de autologin restaurados."

# 3. Limpiar repositorios Copr
echo "[3/4] Eliminando repositorios Copr temporales..."
rm -f /etc/yum.repos.d/_copr_ashbuk-Hyprland-Fedora.repo \
      /etc/yum.repos.d/_copr_solopasha-hyprland.repo
echo "  [✓] Repositorios limpiados."

# 4. Revertir capas en rpm-ostree
echo "[4/4] Revirtiendo capas añadidas en rpm-ostree (rpm-ostree reset)..."
rpm-ostree reset

echo ""
echo "=========================================================="
echo " [✓] ¡Rollback completado con éxito!"
echo " Tu sistema Bazzite ha quedado 100% restaurado al estado base."
echo " Reinicia con: sudo systemctl reboot"
echo "=========================================================="
