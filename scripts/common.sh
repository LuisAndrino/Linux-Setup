#!/usr/bin/env bash
# ==============================================================================
# common.sh - Utilidades compartidas, detección multi-distro y descargas seguras
# ==============================================================================

# Evitar carga duplicada
if [ -n "${_LINUX_SETUP_COMMON_LOADED:-}" ]; then
    return 0
fi
_LINUX_SETUP_COMMON_LOADED=1

# Colores (vacíos si no hay TTY interactivo)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' BLUE='' YELLOW='' CYAN='' MAGENTA='' BOLD='' NC=''
fi

export NONINTERACTIVE=1
export DEBIAN_FRONTEND=noninteractive
export USER="${USER:-$(id -un)}"
export PATH="${HOME}/.local/bin:${HOME}/.bun/bin:/usr/games:/usr/local/bin:${PATH}"

# ------------------------------------------------------------------------------
# Helper de privilegios (funciona tanto como usuario normal con sudo como root)
# ------------------------------------------------------------------------------
SUDO=""
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    fi
fi

run_root() {
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        "$@"
    elif [ -n "${SUDO}" ]; then
        sudo "$@"
    else
        echo -e "${YELLOW}[!] Se requieren permisos root/sudo para: $*${NC}" >&2
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Detección de plataforma, distro, gestor de paquetes y arquitectura
# ------------------------------------------------------------------------------
detect_platform() {
    DISTRO_ID="unknown"
    DISTRO_ID_LIKE=""
    DISTRO_PRETTY="Linux"
    IS_IMMUTABLE=false
    DISTRO_FAMILY="unknown"
    PKG_MGR="none"

    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
        DISTRO_PRETTY="${PRETTY_NAME:-$DISTRO_ID}"
    fi

    if command -v rpm-ostree >/dev/null 2>&1 || [ -f /etc/steamos-release ] || [ "${DISTRO_ID}" = "bazzite" ]; then
        IS_IMMUTABLE=true
    fi

    case "${DISTRO_ID}" in
        ubuntu|debian|pop|linuxmint|mint|elementary|zorin|kali|neon|mx)
            DISTRO_FAMILY="debian"
            ;;
        fedora|rhel|centos|rocky|alma|nobara|bazzite)
            DISTRO_FAMILY="fedora"
            ;;
        arch|cachyos|manjaro|endeavouros|garuda|artix|arcolinux|steamos)
            DISTRO_FAMILY="arch"
            ;;
        opensuse*|suse|sles)
            DISTRO_FAMILY="suse"
            ;;
        *)
            if [[ "${DISTRO_ID_LIKE}" == *debian* ]] || [[ "${DISTRO_ID_LIKE}" == *ubuntu* ]]; then
                DISTRO_FAMILY="debian"
            elif [[ "${DISTRO_ID_LIKE}" == *fedora* ]] || [[ "${DISTRO_ID_LIKE}" == *rhel* ]]; then
                DISTRO_FAMILY="fedora"
            elif [[ "${DISTRO_ID_LIKE}" == *arch* ]]; then
                DISTRO_FAMILY="arch"
            elif [[ "${DISTRO_ID_LIKE}" == *suse* ]]; then
                DISTRO_FAMILY="suse"
            fi
            ;;
    esac

    if [ "${IS_IMMUTABLE}" = true ]; then
        PKG_MGR="immutable"
    elif command -v apt-get >/dev/null 2>&1; then
        PKG_MGR="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MGR="zypper"
    fi

    ARCH="$(uname -m)"
    case "${ARCH}" in
        x86_64|amd64)
            DEB_ARCH="amd64"
            GO_ARCH="x86_64"
            ;;
        aarch64|arm64)
            DEB_ARCH="arm64"
            GO_ARCH="arm64"
            ;;
        *)
            DEB_ARCH="${ARCH}"
            GO_ARCH="${ARCH}"
            ;;
    esac

    HAS_SYSTEMD=false
    if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; then
        HAS_SYSTEMD=true
    fi

    IN_CONTAINER=false
    if [ -f /.dockerenv ] || [ -f /run/.containerenv ] || grep -qaE 'container=|docker|podman|kubepods' /proc/1/environ 2>/dev/null; then
        IN_CONTAINER=true
    fi
}

# ------------------------------------------------------------------------------
# Descargas robustas con timeout, detección de atasco (stall) y reintentos
# Uso: safe_download <url> <archivo_destino> [max_time_seg]
# ------------------------------------------------------------------------------
safe_download() {
    local url="$1"
    local dest="$2"
    local max_time="${3:-300}"
    local tmp_file="${dest}.part.$$"

    mkdir -p "$(dirname "${dest}")"
    rm -f "${tmp_file}"

    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL \
            --connect-timeout 15 \
            --speed-limit 1024 \
            --speed-time 30 \
            --max-time "${max_time}" \
            --retry 3 \
            --retry-delay 2 \
            -o "${tmp_file}" \
            "${url}"; then
            mv -f "${tmp_file}" "${dest}"
            return 0
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q \
            --tries=3 \
            --connect-timeout=15 \
            --read-timeout=30 \
            --timeout="${max_time}" \
            -O "${tmp_file}" \
            "${url}"; then
            mv -f "${tmp_file}" "${dest}"
            return 0
        fi
    else
        echo -e "${RED}[!] Ni curl ni wget están instalados para descargar: ${url}${NC}" >&2
        return 1
    fi

    rm -f "${tmp_file}"
    return 1
}

# Descarga rápida de texto / API / manifest a stdout con timeout corto
# Uso: safe_fetch <url> [max_time_seg]
safe_fetch() {
    local url="$1"
    local max_time="${2:-25}"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL \
            --connect-timeout 10 \
            --speed-limit 512 \
            --speed-time 15 \
            --max-time "${max_time}" \
            --retry 2 \
            --retry-delay 2 \
            "${url}"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- \
            --tries=2 \
            --connect-timeout=10 \
            --read-timeout=15 \
            --timeout="${max_time}" \
            "${url}"
    else
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Helpers de gestores de paquetes (sin bloqueos ni caídas por paquete ausente)
# ------------------------------------------------------------------------------
APT_OPTS=(-y -o DPkg::Lock::Timeout=120 -o Acquire::Retries=3 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30)

apt_update_safe() {
    export DEBIAN_FRONTEND=noninteractive
    run_root dpkg --configure -a >/dev/null 2>&1 || true
    run_root apt-get "${APT_OPTS[@]}" update -qq || run_root apt-get "${APT_OPTS[@]}" update || true
}

apt_has_candidate() {
    local pkg="$1"
    local cand
    cand="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2; exit}' || true)"
    [ -n "$cand" ] && [ "$cand" != "(none)" ]
}

apt_install_list() {
    export DEBIAN_FRONTEND=noninteractive
    local valid=()
    local pkg
    for pkg in "$@"; do
        if apt_has_candidate "$pkg"; then
            valid+=("$pkg")
        else
            echo "  [i] APT: paquete '$pkg' sin candidato instalable en esta versión, omitiendo."
        fi
    done

    if [ ${#valid[@]} -eq 0 ]; then
        return 0
    fi

    echo "  [+] APT: instalando ${#valid[@]} paquete(s)..."
    if ! run_root env DEBIAN_FRONTEND=noninteractive apt-get "${APT_OPTS[@]}" install -qq "${valid[@]}"; then
        echo "  [!] APT: fallo en lote, reparando e instalando paquete por paquete..."
        run_root env DEBIAN_FRONTEND=noninteractive apt-get "${APT_OPTS[@]}" install -f -qq || true
        for pkg in "${valid[@]}"; do
            run_root env DEBIAN_FRONTEND=noninteractive apt-get "${APT_OPTS[@]}" install -qq "$pkg" || \
                echo "  [!] APT: no se pudo instalar '$pkg'"
        done
    fi
}

dnf_install_list() {
    local dnf_opts=(-y --setopt=timeout=30 --setopt=retries=3)
    echo "  [+] DNF: instalando $# paquete(s)..."
    if ! run_root dnf install "${dnf_opts[@]}" --skip-unavailable "$@" 2>/dev/null; then
        if ! run_root dnf install "${dnf_opts[@]}" --skip-broken "$@"; then
            local pkg
            for pkg in "$@"; do
                run_root dnf install "${dnf_opts[@]}" "$pkg" || echo "  [!] DNF: no se pudo instalar '$pkg'"
            done
        fi
    fi
}

pacman_install_list() {
    local avail
    avail="$(pacman -Slq 2>/dev/null || true)"
    local valid=()
    local pkg
    for pkg in "$@"; do
        if [[ $'\n'"${avail}"$'\n' == *$'\n'"${pkg}"$'\n'* ]]; then
            valid+=("$pkg")
        else
            echo "  [i] PACMAN: paquete '$pkg' no disponible en repos habilitados, omitiendo."
        fi
    done

    if [ ${#valid[@]} -eq 0 ]; then
        return 0
    fi

    echo "  [+] PACMAN: instalando ${#valid[@]} paquete(s)..."
    if ! run_root pacman -S --needed --noconfirm "${valid[@]}"; then
        echo "  [!] PACMAN: reintentando paquete por paquete..."
        for pkg in "${valid[@]}"; do
            run_root pacman -S --needed --noconfirm "$pkg" || echo "  [!] PACMAN: no se pudo instalar '$pkg'"
        done
    fi
}

zypper_install_list() {
    local zyp_opts=(--non-interactive --gpg-auto-import-keys)
    echo "  [+] ZYPPER: instalando $# paquete(s)..."
    if ! run_root zypper "${zyp_opts[@]}" install --no-confirm --force-resolution --ignore-unknown "$@" 2>/dev/null; then
        local pkg
        for pkg in "$@"; do
            run_root zypper "${zyp_opts[@]}" install --no-confirm --force-resolution "$pkg" || echo "  [!] ZYPPER: no se pudo instalar '$pkg'"
        done
    fi
}

# ------------------------------------------------------------------------------
# Helper de Flatpak (pre-requisito garantizado + Flathub + fallback --user)
# ------------------------------------------------------------------------------
ensure_flatpak_prereq() {
    if ! command -v flatpak >/dev/null 2>&1; then
        echo "  [+] Instalando pre-requisito Flatpak..."
        case "${PKG_MGR}" in
            apt)    apt_install_list flatpak ;;
            dnf)    dnf_install_list flatpak ;;
            pacman) pacman_install_list flatpak ;;
            zypper) zypper_install_list flatpak ;;
        esac
    fi
    if command -v flatpak >/dev/null 2>&1; then
        flatpak_setup_flathub
        echo "  [✓] Pre-requisito Flatpak + Flathub listo."
    else
        echo "  [!] No se pudo instalar Flatpak en este sistema."
    fi
}

flatpak_setup_flathub() {
    if ! command -v flatpak >/dev/null 2>&1; then
        return 1
    fi
    timeout 45 flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || \
        timeout 45 run_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
    timeout 45 flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
}

flatpak_install_safe() {
    if [ "${LINUX_SETUP_SKIP_FLATPAKS:-0}" = "1" ]; then
        echo "  [i] Flatpak omitido por LINUX_SETUP_SKIP_FLATPAKS=1: $*"
        return 0
    fi
    if ! command -v flatpak >/dev/null 2>&1; then
        echo "  [!] Flatpak no disponible; omitiendo: $*"
        return 1
    fi
    flatpak_setup_flathub
    local batch_timeout=900
    [ $# -eq 1 ] && batch_timeout=240
    if timeout "${batch_timeout}" flatpak install -y --noninteractive flathub "$@" 2>/dev/null; then
        return 0
    fi
    if timeout "${batch_timeout}" flatpak install --user -y --noninteractive flathub "$@" 2>/dev/null; then
        return 0
    fi
    if [ $# -gt 1 ]; then
        local app
        for app in "$@"; do
            timeout 240 flatpak install -y --noninteractive flathub "$app" 2>/dev/null || \
            timeout 240 flatpak install --user -y --noninteractive flathub "$app" 2>/dev/null || \
                echo "  [!] Flatpak: no se pudo instalar '$app' (o excedió timeout)"
        done
    else
        echo "  [!] Flatpak: no se pudo instalar '$1' (o excedió timeout)"
    fi
}

# ------------------------------------------------------------------------------
# Asegurar PATH en perfiles de shell del usuario
# ------------------------------------------------------------------------------
ensure_user_path_in_rc() {
    local line='export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/games:$PATH"'
    local rc
    for rc in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.profile"; do
        if [ -f "$rc" ]; then
            if ! grep -Fq '.local/bin' "$rc" 2>/dev/null; then
                printf '\n# Linux-Setup PATH\n%s\n' "$line" >> "$rc"
            fi
        fi
    done
}

detect_platform
