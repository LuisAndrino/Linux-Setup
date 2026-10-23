#!/usr/bin/env bash
# ==============================================================================
# setup-omarchy-bazzite.sh - Instalador completo de Omarchy (Hyprland) en Bazzite
# ==============================================================================
# 1. Habilita el repositorio Copr de Hyprland para Fedora/Bazzite
# 2. Instala Hyprland, Waybar, Rofi-Wayland, SwayNC, Swaybg y utilidades vía rpm-ostree
# 3. Configura SDDM para permitir cerrar sesión y elegir sesión manualmente (sin autologin forzado)
# 4. Despliega todas las configuraciones, temas y Modo Agente de Omarchy
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================================="
echo "    Instalador de Omarchy Desktop para Bazzite OS         "
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
    echo "[!] Este script requiere permisos de administrador para configurar rpm-ostree y SDDM."
    echo "    Por favor ejecútalo con: sudo $0"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# -----------------------------------------------------------------------------
# 1. Configurar SDDM: Desactivar autologin cíclico para permitir desloguear y elegir sesión
# -----------------------------------------------------------------------------
echo "[1/4] Configurando SDDM para permitir desloguear y seleccionar sesión..."

# Desactivar el servicio de autologin forzado de Bazzite
systemctl mask bazzite-autologin.service 2>/dev/null || true

# Crear drop-in de máxima prioridad para deshabilitar autologin y relogin
cat << 'EOF' > /etc/sddm.conf.d/zz-zzz-manual-session.conf
[Autologin]
User=
Session=
Relogin=false
EOF

# Limpiar archivos de autologin previos
rm -f /etc/sddm.conf.d/zz-bazzite-autologin.conf /etc/sddm.conf.d/zz-holo-autologin.conf

echo "  [✓] SDDM configurado: al cerrar sesión aparecerá la pantalla de selección de usuario y entorno."

# -----------------------------------------------------------------------------
# 2. Habilitar repositorio Copr de Hyprland para Bazzite (ashbuk/Hyprland-Fedora)
# -----------------------------------------------------------------------------
echo "[2/4] Configurando repositorio Copr de Hyprland..."

# Limpiar repo antiguo si existía (solopasha tiene problemas de ABI con Fedora 44)
rm -f /etc/yum.repos.d/_copr_solopasha-hyprland.repo

cat << 'EOF' > /etc/yum.repos.d/_copr_ashbuk-Hyprland-Fedora.repo
[copr:copr.fedorainfracloud.org:ashbuk:Hyprland-Fedora]
name=Copr repo for Hyprland-Fedora owned by ashbuk
baseurl=https://download.copr.fedorainfracloud.org/results/ashbuk/Hyprland-Fedora/fedora-$releasever-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/ashbuk/Hyprland-Fedora/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

echo "  [✓] Repositorio de Hyprland configurado en /etc/yum.repos.d/_copr_ashbuk-Hyprland-Fedora.repo"

# -----------------------------------------------------------------------------
# 3. Desplegar archivos de configuración de Omarchy en el usuario
# -----------------------------------------------------------------------------
echo "[3/4] Desplegando configuraciones y temas de Omarchy en el usuario ${REAL_USER}..."

su - "${REAL_USER}" -c "${SCRIPT_DIR}/omarchy-desktop/install.sh"

echo "  [✓] Configuraciones, atajos y temas aplicados para ${REAL_USER}."

# -----------------------------------------------------------------------------
# 4. Instalar paquetes de Hyprland y entorno en rpm-ostree
# -----------------------------------------------------------------------------
echo "[4/4] Instalando paquetes del sistema mediante rpm-ostree..."
echo "  Paquetes: hyprland, xdg-desktop-portal-hyprland, waybar, rofi-wayland, swaync, swaybg, grim, slurp"

PKGS=(
    hyprland
    xdg-desktop-portal-hyprland
    waybar
    rofi-wayland
    swaync
    swaybg
    grim
    slurp
)

# Limpiar caché de transacciones previas
rpm-ostree cleanup -m 2>/dev/null || true

# Ejecutar instalación con rpm-ostree
# Nota: Usamos --force-replacefiles para permitir sobrescribir symlinks de desarrollo (como libdrm.so) preexistentes en la imagen base de Bazzite
rpm-ostree install -y --force-replacefiles "${PKGS[@]}"

echo ""
echo "=========================================================="
echo " [✓] ¡Instalación de Omarchy completada con éxito!"
echo "=========================================================="
echo " Para aplicar la nueva capa del sistema y arrancar Hyprland:"
echo "   sudo systemctl reboot"
echo ""
echo " Al reiniciar, SDDM te mostrará la pantalla de inicio de sesión"
echo " donde podrás elegir 'Hyprland' o 'Plasma' en el selector."
echo "=========================================================="
