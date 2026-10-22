#!/usr/bin/env bash
# ==============================================================================
# export-my-apps.sh - Exporta los programas instalados en la máquina actual
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FLATPAK="${SCRIPT_DIR}/packages/flatpak-apps.txt"
EXPORT_DIR="${SCRIPT_DIR}/packages/system-exports"

mkdir -p "${EXPORT_DIR}"

echo "=========================================================="
echo "      Exportador de Paquetes y Aplicaciones de Usuario    "
echo "=========================================================="

# Función para añadir etiquetas legibles a IDs populares
get_app_description() {
    case "$1" in
        "com.visualstudio.code") echo "Visual Studio Code" ;;
        "org.apache.netbeans") echo "Apache NetBeans IDE" ;;
        "com.brave.Browser") echo "Navegador Brave" ;;
        "com.google.Chrome") echo "Google Chrome" ;;
        "org.mozilla.firefox") echo "Mozilla Firefox" ;;
        "com.onepassword.OnePassword") echo "1Password" ;;
        "com.spotify.Client") echo "Spotify" ;;
        "org.videolan.VLC") echo "VLC Media Player" ;;
        "org.kde.haruna") echo "Haruna Video Player" ;;
        "org.kde.gwenview") echo "Visor de imágenes Gwenview" ;;
        "org.kde.okular") echo "Lector de PDF Okular" ;;
        "org.kde.kcalc") echo "Calculadora KCalc" ;;
        "com.github.tchx84.Flatseal") echo "Gestor de permisos Flatseal" ;;
        "io.github.flattool.Warehouse") echo "Gestor de Flatpaks Warehouse" ;;
        "io.github.DenysMb.Kontainer") echo "GUI de contenedores Kontainer" ;;
        "com.github.Matoking.protontricks") echo "Protontricks" ;;
        "com.vysp3r.ProtonPlus") echo "ProtonPlus" ;;
        "org.gnome.Firmware") echo "Actualizador de Firmware" ;;
        *) echo "" ;;
    esac
}

# 1. Exportar Flatpaks instalados desde Flathub
if command -v flatpak >/dev/null 2>&1; then
    echo "[+] Extrayendo Flatpaks instalados desde Flathub..."
    INSTALLED_FLATPAKS=$(flatpak list --app --columns=application,origin | awk '$2=="flathub" {print $1}' | sort -u)

    # Asegurar que VS Code y NetBeans se mantengan si el usuario los quiere siempre
    MUST_HAVE=("com.visualstudio.code" "org.apache.netbeans")

    TEMP_FILE=$(mktemp)
    cat << 'EOF' > "${TEMP_FILE}"
# ==============================================================================
# Lista de aplicaciones Flatpak (Flathub) - Actualizada automáticamente
# ==============================================================================
# Las líneas que empiezan por '#' son comentarios.
# Puedes añadir nuevos IDs de Flathub directamente aquí.
# ==============================================================================
EOF

    echo "# Fecha de última exportación: $(date)" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"

    # Unir instaladas con must-have
    ALL_FLATPAKS=$(printf "%s\n%s\n" "${INSTALLED_FLATPAKS}" "${MUST_HAVE[*]}" | tr ' ' '\n' | grep -v '^$' | sort -u)

    for app in ${ALL_FLATPAKS}; do
        desc=$(get_app_description "$app")
        if [ -n "$desc" ]; then
            printf "%-36s # %s\n" "$app" "$desc" >> "${TEMP_FILE}"
        else
            echo "$app" >> "${TEMP_FILE}"
        fi
    done

    mv "${TEMP_FILE}" "${OUTPUT_FLATPAK}"
    echo "[✓] Lista Flatpak actualizada en: ${OUTPUT_FLATPAK}"
    echo "    Total de aplicaciones Flatpak registradas: $(grep -v '^#' "${OUTPUT_FLATPAK}" | grep -v '^$' | wc -l)"
else
    echo "[!] Flatpak no está instalado en este sistema."
fi

# 2. Exportar paquetes según el gestor nativo de la máquina actual (referencia)
echo "[+] Exportando lista de paquetes nativos del sistema..."

if command -v pacman >/dev/null 2>&1; then
    pacman -Qqe > "${EXPORT_DIR}/arch-packages.txt" 2>/dev/null || true
    echo "[✓] Paquetes Arch exportados a: ${EXPORT_DIR}/arch-packages.txt"
elif command -v dpkg >/dev/null 2>&1; then
    dpkg --get-selections | awk '{print $1}' > "${EXPORT_DIR}/debian-packages.txt" 2>/dev/null || true
    echo "[✓] Paquetes Debian/Ubuntu exportados a: ${EXPORT_DIR}/debian-packages.txt"
elif command -v rpm >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        dnf repoquery --userinstalled --qf '%{name}' > "${EXPORT_DIR}/fedora-user-packages.txt" 2>/dev/null || true
    fi
    rpm -qa --qf '%{name}\n' | sort > "${EXPORT_DIR}/rpm-all-packages.txt" 2>/dev/null || true
    echo "[✓] Paquetes RPM exportados a: ${EXPORT_DIR}/"
fi

# 3. Exportar paquetes de Homebrew (si está instalado)
if command -v brew >/dev/null 2>&1; then
    brew leaves > "${EXPORT_DIR}/brew-formulae.txt" 2>/dev/null || true
    brew list --cask > "${EXPORT_DIR}/brew-casks.txt" 2>/dev/null || true
    echo "[✓] Fórmulas de Homebrew exportadas a: ${EXPORT_DIR}/"
fi

echo ""
echo "=========================================================="
echo " ¡Exportación completada exitosamente!"
echo " Puedes sincronizar estos cambios con tu repositorio Git:"
echo "   git add packages/"
echo "   git commit -m 'Actualizar lista de programas instalados'"
echo "   git push"
echo "=========================================================="
