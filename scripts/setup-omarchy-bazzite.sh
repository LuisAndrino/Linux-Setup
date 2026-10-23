#!/usr/bin/env bash
# ==============================================================================
# setup-omarchy-bazzite.sh - Instalador completo de Omarchy (Hyprland) en Bazzite
# ==============================================================================
# 1. Configura SDDM para permitir cerrar sesión y elegir sesión manualmente (sin bucle de autologin)
# 2. Instala dependencias del sistema vía rpm-ostree (Waybar, Rofi, SwayNC, Swaybg, utilidades, muParser, tomlplusplus)
# 3. Instala el compositor Hyprland optimizado y autocontenido en /usr/local (sin colisiones con la imagen base)
# 4. Registra la sesión Wayland en SDDM (/usr/local/share/wayland-sessions/hyprland.desktop)
# 5. Despliega todas las configuraciones, temas y Modo Agente de Omarchy
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

systemctl mask bazzite-autologin.service 2>/dev/null || true

# Crear drop-in de máxima prioridad para deshabilitar autologin y relogin
cat << 'EOF' > /etc/sddm.conf.d/zz-zzz-manual-session.conf
[Autologin]
User=
Session=
Relogin=false

[Wayland]
SessionDir=/usr/local/share/wayland-sessions,/usr/share/wayland-sessions
EOF

rm -f /etc/sddm.conf.d/zz-bazzite-autologin.conf /etc/sddm.conf.d/zz-holo-autologin.conf

echo "  [✓] SDDM configurado: al cerrar sesión aparecerá la pantalla de selección de usuario y entorno."

# -----------------------------------------------------------------------------
# 2. Instalar paquetes de utilidades y librerías vía rpm-ostree
# -----------------------------------------------------------------------------
echo "[2/4] Instalando dependencias del entorno gráfico vía rpm-ostree..."
echo "  Paquetes: waybar, rofi-wayland, swaync, swaybg, grim, slurp, muParser, tomlplusplus"

PKGS=(
    waybar
    rofi-wayland
    swaync
    swaybg
    grim
    slurp
    muParser
    tomlplusplus
)

# Limpiar cache de transacciones previas
rpm-ostree cleanup -m 2>/dev/null || true

# Instalar paquetes limpios
rpm-ostree install -y "${PKGS[@]}"

# -----------------------------------------------------------------------------
# 3. Instalar Hyprland autocontenido en /usr/local (evita colisiones con libdrm de Bazzite)
# -----------------------------------------------------------------------------
echo "[3/4] Instalando compositor Hyprland en /usr/local..."

TMP_DIR="/tmp/hypr-bazzite-install"
mkdir -p "${TMP_DIR}"

HYPR_RPM="${TMP_DIR}/hyprland.rpm"
if [ ! -f "${HYPR_RPM}" ]; then
    echo "  -> Descargando Hyprland para Fedora 44..."
    curl -sLo "${HYPR_RPM}" "https://download.copr.fedorainfracloud.org/results/ashbuk/Hyprland-Fedora/fedora-44-x86_64/Packages/h/hyprland-0.56.2-2.fc44.x86_64.rpm"
fi

echo "  -> Desempaquetando binarios y librerías vendored en /usr/local..."
mkdir -p "${TMP_DIR}/extracted"
cd "${TMP_DIR}/extracted"
rpm2cpio "${HYPR_RPM}" | cpio -idm 2>/dev/null

mkdir -p /usr/local/bin /usr/local/libexec /usr/local/share/wayland-sessions /usr/local/share/xdg-desktop-portal /usr/local/share/hypr

cp -rf usr/bin/* /usr/local/bin/
cp -rf usr/libexec/hyprland /usr/local/libexec/
cp -rf usr/share/hypr/* /usr/local/share/hypr/ 2>/dev/null || true
cp -rf usr/share/xdg-desktop-portal/* /usr/local/share/xdg-desktop-portal/ 2>/dev/null || true

# Desktop entry para SDDM
cat << 'EOF' > /usr/local/share/wayland-sessions/hyprland.desktop
[Desktop Entry]
Name=Hyprland (Omarchy)
Comment=An intelligent dynamic tiling Wayland compositor
Exec=/usr/local/bin/Hyprland
Type=Application
DesktopNames=Hyprland
EOF

chmod +x /usr/local/bin/Hyprland /usr/local/bin/hyprctl /usr/local/bin/hyprpm /usr/local/bin/start-hyprland
chmod +r /usr/local/share/wayland-sessions/hyprland.desktop

# Limpiar temporales
rm -rf "${TMP_DIR}"

echo "  [✓] Hyprland instalado en /usr/local/bin/Hyprland"
echo "  [✓] Sesión registrada en /usr/local/share/wayland-sessions/hyprland.desktop"

# -----------------------------------------------------------------------------
# 4. Desplegar archivos de configuración de Omarchy en el usuario
# -----------------------------------------------------------------------------
echo "[4/4] Desplegando configuraciones y temas de Omarchy en el usuario ${REAL_USER}..."

su - "${REAL_USER}" -c "${SCRIPT_DIR}/omarchy-desktop/install.sh"

echo "  [✓] Configuraciones, atajos y temas aplicados para ${REAL_USER}."

echo ""
echo "=========================================================="
echo " [✓] ¡Instalación de Omarchy completada con éxito!"
echo "=========================================================="
echo " Para aplicar la nueva capa del sistema y arrancar Hyprland:"
echo "   sudo systemctl reboot"
echo ""
echo " Al reiniciar, SDDM te mostrará la pantalla de bienvenida"
echo " donde podrás elegir 'Hyprland (Omarchy)' o 'Plasma'."
echo "=========================================================="
