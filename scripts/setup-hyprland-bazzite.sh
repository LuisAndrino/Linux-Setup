#!/usr/bin/env bash
# ==============================================================================
# setup-hyprland-bazzite.sh - Instalador de Hyprland Ligero en Bazzite OS
# ==============================================================================
# 1. Configura SDDM para permitir elegir sesión al desloguear (sin bucle a gaming mode)
# 2. Instala dependencias ligeras en rpm-ostree (Waybar, Rofi, SwayNC, Swaybg, etc.)
# 3. Instala el compositor Hyprland autocontenido en /usr/local con wrapper de entorno
# 4. Registra la sesión Wayland en SDDM (/usr/local/share/wayland-sessions/hyprland.desktop)
# 5. Despliega los dotfiles limpios estilo Omarchy en el usuario
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================================="
echo "    Instalador de Hyprland Ligero para Bazzite OS        "
echo "=========================================================="

if [ "$EUID" -ne 0 ]; then
    echo "[!] Este script requiere permisos de administrador."
    echo "    Por favor ejecútalo con: sudo $0"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# -----------------------------------------------------------------------------
# 1. Configurar SDDM
# -----------------------------------------------------------------------------
echo "[1/4] Configurando SDDM para permitir desloguear y seleccionar sesión..."

systemctl mask bazzite-autologin.service 2>/dev/null || true

cat << 'EOF' > /etc/sddm.conf.d/zz-zzz-manual-session.conf
[Autologin]
User=
Session=
Relogin=false

[Wayland]
SessionDir=/usr/local/share/wayland-sessions,/usr/share/wayland-sessions
EOF

rm -f /etc/sddm.conf.d/zz-bazzite-autologin.conf /etc/sddm.conf.d/zz-holo-autologin.conf
echo "  [✓] SDDM configurado: al cerrar sesión se podrá elegir entorno libremente."

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

rpm-ostree cleanup -m 2>/dev/null || true
rpm-ostree install -y "${PKGS[@]}"

# -----------------------------------------------------------------------------
# 3. Instalar Hyprland en /usr/local con wrapper seguro
# -----------------------------------------------------------------------------
echo "[3/4] Instalando compositor Hyprland en /usr/local..."

TMP_DIR="/tmp/hypr-bazzite-install"
mkdir -p "${TMP_DIR}"

HYPR_RPM="${TMP_DIR}/hyprland.rpm"
if [ ! -f "${HYPR_RPM}" ]; then
    echo "  -> Descargando Hyprland para Fedora 44..."
    curl -sLo "${HYPR_RPM}" "https://download.copr.fedorainfracloud.org/results/ashbuk/Hyprland-Fedora/fedora-44-x86_64/Packages/h/hyprland-0.56.2-2.fc44.x86_64.rpm"
fi

echo "  -> Desempaquetando binarios y librerías en /usr/local..."
mkdir -p "${TMP_DIR}/extracted"
cd "${TMP_DIR}/extracted"
rpm2cpio "${HYPR_RPM}" | cpio -idm 2>/dev/null

mkdir -p /usr/local/bin \
         /usr/local/libexec \
         /usr/local/share/wayland-sessions \
         /usr/local/share/xdg-desktop-portal \
         /usr/local/share/hypr

# Copiar binarios originales
cp -rf usr/bin/* /usr/local/bin/
cp -rf usr/libexec/hyprland /usr/local/libexec/
cp -rf usr/share/hypr/* /usr/local/share/hypr/ 2>/dev/null || true
cp -rf usr/share/xdg-desktop-portal/* /usr/local/share/xdg-desktop-portal/ 2>/dev/null || true

# Crear script lanzador con variables de entorno completas para Wayland/Bazzite
cat << 'EOF' > /usr/local/bin/start-hyprland-session
#!/usr/bin/env bash
# Wrapper para inicialización limpia de Hyprland en Bazzite
export LD_LIBRARY_PATH="/usr/local/libexec/hyprland/vendor/lib64:${LD_LIBRARY_PATH:-}"
export XDG_CURRENT_DESKTOP="Hyprland"
export XDG_SESSION_DESKTOP="Hyprland"
export XDG_SESSION_TYPE="wayland"
export _JAVA_AWT_WM_NONREPARENTING=1
export GDK_BACKEND="wayland,x11"
export QT_QPA_PLATFORM="wayland;xcb"
export SDL_VIDEODRIVER="wayland"
export CLUTTER_BACKEND="wayland"

# Importar variables al entorno systemd y dbus de usuario
systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true
dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true

exec /usr/local/bin/Hyprland
EOF

chmod +x /usr/local/bin/start-hyprland-session
chmod +x /usr/local/bin/Hyprland /usr/local/bin/hyprctl /usr/local/bin/hyprpm

# Entrada .desktop para SDDM
cat << 'EOF' > /usr/local/share/wayland-sessions/hyprland.desktop
[Desktop Entry]
Name=Hyprland
Comment=Dynamic tiling Wayland compositor (Estilo Omarchy)
Exec=/usr/local/bin/start-hyprland-session
Type=Application
DesktopNames=Hyprland
EOF

chmod +r /usr/local/share/wayland-sessions/hyprland.desktop
rm -rf "${TMP_DIR}"

echo "  [✓] Hyprland instalado con éxito en /usr/local."

# -----------------------------------------------------------------------------
# 4. Desplegar configuraciones limpias en el usuario
# -----------------------------------------------------------------------------
echo "[4/4] Desplegando configuraciones y temas en ${REAL_USER}..."
su - "${REAL_USER}" -c "${SCRIPT_DIR}/hyprland-desktop/install.sh"

echo ""
echo "=========================================================="
echo " [✓] ¡Instalación de Hyprland completada con éxito!"
echo "=========================================================="
echo " Para aplicar los cambios del sistema y probar el entorno:"
echo "   sudo systemctl reboot"
echo ""
echo " Al reiniciar, selecciona 'Hyprland' en la pantalla de SDDM."
echo "=========================================================="
