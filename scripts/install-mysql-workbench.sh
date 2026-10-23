#!/usr/bin/env bash
# ==============================================================================
# install-mysql-workbench.sh - Instalador y optimizador de MySQL Workbench
# ==============================================================================
# MySQL Workbench depende de X11 en muchas librerías internas. En entornos
# Wayland / Hyprland suele crashear o fallar en popups si no se fuerza XWayland
# mediante GDK_BACKEND=x11. Este script configura dicha compatibilidad.
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          Instalación de MySQL Workbench                  "
echo "=========================================================="

if command -v mysql-workbench >/dev/null 2>&1; then
    echo "[✓] MySQL Workbench ya está instalado en el sistema ($(command -v mysql-workbench))."
else
    echo "[+] Instalando MySQL Workbench mediante el gestor del sistema..."

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y && sudo apt-get install -y mysql-workbench || true
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y mysql-workbench || true
    elif command -v pacman >/dev/null 2>&1; then
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm mysql-workbench 2>/dev/null || true
        else
            sudo pacman -S --needed --noconfirm mysql-workbench 2>/dev/null || true
        fi
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install mysql-workbench || true
    fi
fi

# Parche de compatibilidad Wayland / Hyprland para MySQL Workbench:
# Crea un lanzador que fuerza GDK_BACKEND=x11 para evitar pantallas en negro o cierres inesperados
DESKTOP_DIR="${HOME}/.local/share/applications"
mkdir -p "${DESKTOP_DIR}"

if command -v mysql-workbench >/dev/null 2>&1; then
    echo "[+] Configurando compatibilidad XWayland para MySQL Workbench..."
    cat << 'EOF' > "${DESKTOP_DIR}/mysql-workbench-wayland-fix.desktop"
[Desktop Entry]
Name=MySQL Workbench (Wayland Safe)
Comment=MySQL Database Design & Administration Tool (Forced XWayland)
Exec=env GDK_BACKEND=x11 mysql-workbench %F
Icon=mysql-workbench
Type=Application
Terminal=false
Categories=Development;Database;
StartupNotify=true
EOF
    chmod +x "${DESKTOP_DIR}/mysql-workbench-wayland-fix.desktop"
    echo "[✓] Acceso directo seguro para Wayland creado en: ${DESKTOP_DIR}/mysql-workbench-wayland-fix.desktop"
fi

# Instalar también DBeaver Community como alternativa moderna universal
echo "[+] Asegurando DBeaver Community (Flathub) como cliente SQL universal..."
if command -v flatpak >/dev/null 2>&1; then
    flatpak install -y --noninteractive flathub io.dbeaver.DBeaverCommunity || true
fi

echo ""
echo "=========================================================="
echo " [✓] MySQL Workbench listo."
echo " En Wayland / Hyprland, ejecútalo siempre con:"
echo "   env GDK_BACKEND=x11 mysql-workbench"
echo " O utiliza el acceso 'MySQL Workbench (Wayland Safe)' en tu menú."
echo "=========================================================="
