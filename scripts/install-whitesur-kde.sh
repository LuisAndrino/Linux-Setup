#!/usr/bin/env bash
# ==============================================================================
# install-whitesur-kde.sh - Instala el tema WhiteSur completo si el usuario usa KDE
# ==============================================================================
# Instala automáticamente (solo si KDE Plasma está presente):
#  1. Dependencias del sistema: Kvantum (Qt6/Qt5), sassc, glib2, libxml2, murrine
#  2. WhiteSur-kde (Global Theme, Plasma Theme, Aurorae, Kvantum, Color Schemes, Wallpapers)
#  3. WhiteSur-icon-theme (Iconos estilo macOS + variantes)
#  4. WhiteSur-cursors (Cursores estilo macOS)
#  5. WhiteSur-gtk-theme (Para que las apps GTK/Flatpak coincidan con KDE)
#  6. Configuración automática de Kvantum (y aplicación en sesión KDE activa)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

echo "=== Tema WhiteSur para KDE Plasma ==="

# ------------------------------------------------------------------------------
# 1. Detectar si el sistema usa KDE Plasma
# ------------------------------------------------------------------------------
IS_KDE=false
if [ "${LINUX_SETUP_FORCE_KDE_THEME:-0}" = "1" ]; then
    IS_KDE=true
elif printf '%s %s %s' "${XDG_CURRENT_DESKTOP:-}" "${XDG_SESSION_DESKTOP:-}" "${DESKTOP_SESSION:-}" | grep -qiE 'kde|plasma'; then
    IS_KDE=true
elif command -v plasmashell >/dev/null 2>&1 || \
     command -v startplasma-wayland >/dev/null 2>&1 || \
     command -v startplasma-x11 >/dev/null 2>&1 || \
     [ -f /usr/share/wayland-sessions/plasma.desktop ] || \
     [ -f /usr/share/xsessions/plasma.desktop ]; then
    IS_KDE=true
fi

if [ "${IS_KDE}" = false ]; then
    echo "  [i] Entorno KDE Plasma no detectado; omitiendo tema WhiteSur."
    exit 0
fi

echo "  [✓] Entorno KDE Plasma detectado. Instalando dependencias y tema WhiteSur..."

# ------------------------------------------------------------------------------
# 2. Instalar dependencias por distribución (Kvantum + motores GTK/Sass)
# ------------------------------------------------------------------------------
case "${PKG_MGR}" in
    apt)
        apt_install_list \
            sudo qt6-style-kvantum qt6-style-kvantum-themes \
            qt5-style-kvantum qt5-style-kvantum-themes \
            sassc libglib2.0-dev-bin libxml2-utils \
            gtk2-engines-murrine gtk2-engines-pixbuf imagemagick
        ;;
    dnf)
        dnf_install_list \
            sudo which kvantum kvantum-qt5 \
            sassc glib2-devel libxml2 \
            gtk-murrine-engine gtk2-engines
        ;;
    pacman)
        pacman_install_list \
            sudo which kvantum kvantum-qt5 \
            sassc glib2 libxml2 \
            gtk-engine-murrine gtk-engines
        ;;
    zypper)
        zypper_install_list \
            sudo which kvantum-manager kvantum-qt6 kvantum-qt5 \
            sassc glib2-tools libxml2-tools \
            gtk2-engine-murrine
        ;;
    immutable)
        echo "  [i] Sistema inmutable detectado: usando dependencias del sistema e instalando temas en espacio de usuario."
        ;;
esac

# ------------------------------------------------------------------------------
# Helper: descargar tarball de GitHub con timeout/reintentos y ejecutar install.sh
# ------------------------------------------------------------------------------
TMP_BASE="/tmp/whitesur-install-$$"
mkdir -p "${TMP_BASE}"
trap 'rm -rf "${TMP_BASE}"' EXIT

install_whitesur_repo() {
    local repo="$1"
    shift
    local label="$1"
    shift
    local url="https://github.com/vinceliuice/${repo}/archive/refs/heads/master.tar.gz"
    local tar_file="${TMP_BASE}/${repo}.tar.gz"
    local work_dir="${TMP_BASE}/${repo}"

    echo "  [+] Descargando e instalando ${label}..."
    if ! safe_download "${url}" "${tar_file}" 240; then
        echo "  [!] No se pudo descargar ${repo}."
        return 1
    fi

    mkdir -p "${work_dir}"
    if ! tar -xzf "${tar_file}" -C "${work_dir}" --strip-components=1 2>/dev/null; then
        echo "  [!] Error al extraer ${repo}."
        return 1
    fi

    if [ -f "${work_dir}/install.sh" ]; then
        chmod +x "${work_dir}/install.sh"
        (
            cd "${work_dir}"
            timeout 240 bash ./install.sh "$@" >/dev/null 2>&1
        ) && echo "  [✓] ${label} instalado." || echo "  [!] ${label} terminó con advertencias."
    fi
    rm -rf "${tar_file}" "${work_dir}"
}

# ------------------------------------------------------------------------------
# 3. Instalar componentes oficiales de WhiteSur
# ------------------------------------------------------------------------------
# 3.1 WhiteSur KDE (Global Theme, Plasma Theme, Aurorae, Kvantum, Color Schemes, Wallpapers)
install_whitesur_repo "WhiteSur-kde" "WhiteSur KDE Theme" || true

# 3.2 WhiteSur Icon Theme (con íconos alternativos y panel bold)
install_whitesur_repo "WhiteSur-icon-theme" "WhiteSur Icon Theme" -a -b || true

# 3.3 WhiteSur Cursors
install_whitesur_repo "WhiteSur-cursors" "WhiteSur Cursors" || true

# 3.4 WhiteSur GTK Theme (para coherencia visual de apps GTK/Flatpak en KDE)
# Nota: --silent-mode evita fallo de 'setterm -cursor off' cuando no hay TTY (ej. curl | bash)
install_whitesur_repo "WhiteSur-gtk-theme" "WhiteSur GTK Theme" --silent-mode || true

# Permitir que apps Flatpak lean el tema GTK del usuario
if command -v flatpak >/dev/null 2>&1; then
    flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
    flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
    flatpak override --user --filesystem=xdg-data/themes:ro 2>/dev/null || true
    flatpak override --user --filesystem=xdg-data/icons:ro 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 4. Configurar Kvantum y aplicar tema en KDE si hay sesión gráfica activa
# ------------------------------------------------------------------------------
KVANTUM_CONF_DIR="${HOME}/.config/Kvantum"
mkdir -p "${KVANTUM_CONF_DIR}"
KV_THEME="WhiteSurDark"
if [ -d "${KVANTUM_CONF_DIR}/WhiteSur" ] || [ -d "/usr/share/Kvantum/WhiteSur" ]; then
    if [ ! -f "${KVANTUM_CONF_DIR}/WhiteSur/WhiteSurDark.kvconfig" ] && [ ! -f "/usr/share/Kvantum/WhiteSur/WhiteSurDark.kvconfig" ]; then
        KV_THEME="WhiteSur"
    fi
fi

if command -v kvantummanager >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    kvantummanager --set "${KV_THEME}" >/dev/null 2>&1 || true
else
    cat << EOF > "${KVANTUM_CONF_DIR}/kvantum.kvconfig"
[General]
theme=${KV_THEME}
EOF
fi

if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && [ "${IN_CONTAINER}" = false ]; then
    if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
        plasma-apply-lookandfeel -a com.github.vinceliuice.WhiteSur-dark >/dev/null 2>&1 || \
            plasma-apply-lookandfeel -a com.github.vinceliuice.WhiteSur >/dev/null 2>&1 || true
    fi
    if command -v plasma-apply-cursortheme >/dev/null 2>&1; then
        plasma-apply-cursortheme WhiteSur-cursors >/dev/null 2>&1 || true
    fi
    KWRITE=""
    command -v kwriteconfig6 >/dev/null 2>&1 && KWRITE="kwriteconfig6"
    [ -z "${KWRITE}" ] && command -v kwriteconfig5 >/dev/null 2>&1 && KWRITE="kwriteconfig5"
    if [ -n "${KWRITE}" ]; then
        "${KWRITE}" --file kdeglobals --group KDE --key widgetStyle kvantum-dark >/dev/null 2>&1 || true
    fi
    echo "  [✓] Tema WhiteSur aplicado en tu sesión de KDE Plasma."
else
    echo "  [✓] Tema WhiteSur instalado. Selecciónalo en Preferencias del Sistema -> Apariencia -> Tema Global (WhiteSur) y Estilo de aplicación -> Kvantum."
fi
