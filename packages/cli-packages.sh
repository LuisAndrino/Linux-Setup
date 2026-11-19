#!/usr/bin/env bash
# ==============================================================================
# cli-packages.sh - Pre-requisitos del sistema, herramientas CLI y bases gaming
# ==============================================================================
# Compatible con: Ubuntu, Debian, Fedora, Arch Linux, openSUSE, Bazzite, SteamOS
# ==============================================================================

_CLI_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_CLI_SCRIPT_DIR}/../scripts/common.sh"

install_cli_debian() {
    apt_update_safe

    # 1. Pre-requisitos mínimos para repositorios externos, HTTPS, GPG y EULAs
    local bootstrap_pkgs=(curl wget ca-certificates gnupg apt-transport-https debconf-utils)
    if [[ "${DISTRO_ID}" == "ubuntu" ]] || [[ "${DISTRO_ID_LIKE}" == *ubuntu* ]]; then
        bootstrap_pkgs+=(software-properties-common)
    fi
    apt_install_list "${bootstrap_pkgs[@]}"

    # 2. Habilitar repositorios comunitarios/propietarios necesarios
    if [[ "${DISTRO_ID}" == "ubuntu" ]] || [[ "${DISTRO_ID_LIKE}" == *ubuntu* ]]; then
        if command -v add-apt-repository >/dev/null 2>&1; then
            run_root add-apt-repository -y universe >/dev/null 2>&1 || true
            run_root add-apt-repository -y multiverse >/dev/null 2>&1 || true
        fi
    elif [[ "${DISTRO_ID}" == "debian" ]]; then
        # Habilitar contrib y non-free en Debian para Steam / códecs / drivers
        if [ -f /etc/apt/sources.list.d/debian.sources ]; then
            run_root sed -i 's/^Components: main$/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
            run_root sed -i 's/^Components: main non-free-firmware$/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
        elif [ -f /etc/apt/sources.list ]; then
            run_root sed -i -E 's/(deb\s+\S+\s+\S+\s+main)$/\1 contrib non-free non-free-firmware/' /etc/apt/sources.list 2>/dev/null || true
        fi
    fi

    # 3. Habilitar arquitectura i386 (solo en x86_64) para Steam / Proton / Wine
    if [ "${DEB_ARCH}" = "amd64" ]; then
        run_root dpkg --add-architecture i386 2>/dev/null || true
    fi

    apt_update_safe

    # 4. Paquetes base, pre-requisitos de apps, CLI, multimedia y gaming
    local pkgs=(
        curl wget git gh jq ripgrep tree rsync fzf zoxide fd-find
        htop btop tmux zsh zip unzip tar xz-utils zstd p7zip-full bat
        build-essential ca-certificates gnupg openssl apt-transport-https debconf-utils
        openssh-client alacritty
        ffmpeg mpv vlc gamemode mangohud gamescope
        vulkan-tools mesa-vulkan-drivers
        adb fastboot python3 python3-pip flatpak
    )

    if command -v gnome-software >/dev/null 2>&1; then
        pkgs+=(gnome-software-plugin-flatpak)
    fi

    # FUSE2 para AppImages en Ubuntu 22.04/24.04+ y Debian 12+
    if apt_has_candidate libfuse2t64; then
        pkgs+=(libfuse2t64)
    elif apt_has_candidate libfuse2; then
        pkgs+=(libfuse2)
    fi

    # OpenJDK 21 o fallback a default-jdk
    if apt_has_candidate openjdk-21-jdk; then
        pkgs+=(openjdk-21-jdk)
    elif apt_has_candidate default-jdk; then
        pkgs+=(default-jdk)
    fi

    # fastfetch o fallback a neofetch
    if apt_has_candidate fastfetch; then
        pkgs+=(fastfetch)
    elif apt_has_candidate neofetch; then
        pkgs+=(neofetch)
    fi

    apt_install_list "${pkgs[@]}"

    # En Debian/Ubuntu bat es batcat y fd es fdfind
    mkdir -p "${HOME}/.local/bin"
    if command -v batcat >/dev/null 2>&1 && [ ! -e "${HOME}/.local/bin/bat" ]; then
        ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
    fi
    if command -v fdfind >/dev/null 2>&1 && [ ! -e "${HOME}/.local/bin/fd" ]; then
        ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
    fi
}

install_cli_fedora() {
    if [ -f /etc/dnf/dnf.conf ]; then
        if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf 2>/dev/null; then
            echo "max_parallel_downloads=10" | run_root tee -a /etc/dnf/dnf.conf >/dev/null 2>&1 || true
        fi
        if ! grep -q "fastestmirror" /etc/dnf/dnf.conf 2>/dev/null; then
            echo "fastestmirror=True" | run_root tee -a /etc/dnf/dnf.conf >/dev/null 2>&1 || true
        fi
    fi

    local pkgs=(
        curl wget git gh jq ripgrep fd-find tree rsync fzf bat zoxide
        htop btop tmux zsh zip unzip tar xz zstd p7zip p7zip-plugins
        gcc gcc-c++ make ca-certificates gnupg2 openssl openssh-clients
        fastfetch alacritty mpv gamemode mangohud gamescope
        vulkan-tools mesa-vulkan-drivers
        android-tools java-21-openjdk-devel python3 python3-pip flatpak
        fuse fuse-libs
    )
    dnf_install_list "${pkgs[@]}"
}

install_cli_arch() {
    if [ -f /etc/pacman.conf ]; then
        run_root sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf 2>/dev/null || true
        if ! grep -q "^ParallelDownloads" /etc/pacman.conf 2>/dev/null; then
            run_root sed -i '/^\[options\]/a ParallelDownloads = 10' /etc/pacman.conf 2>/dev/null || true
        fi
        if [ "${ARCH}" = "x86_64" ] && ! grep -qE '^\[multilib\]' /etc/pacman.conf 2>/dev/null; then
            echo "  [+] Habilitando repositorio [multilib] en /etc/pacman.conf..."
            if grep -qE '^#\[multilib\]' /etc/pacman.conf 2>/dev/null; then
                run_root sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf 2>/dev/null || true
            else
                printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | run_root tee -a /etc/pacman.conf >/dev/null 2>&1 || true
            fi
        fi
    fi

    echo "  [+] PACMAN: sincronizando bases de datos y actualizando sistema..."
    run_root pacman -Syu --noconfirm || run_root pacman -Sy --noconfirm || true

    local pkgs=(
        curl wget git github-cli jq ripgrep fd tree rsync fzf bat zoxide
        htop btop tmux zsh zip unzip tar xz zstd 7zip
        base-devel ca-certificates gnupg openssl openssh fastfetch alacritty
        ffmpeg mpv vlc gamemode mangohud gamescope vulkan-tools
        android-tools jdk-openjdk python python-pip
        flatpak fuse2 firefox code tailscale
    )

    if [ "${ARCH}" = "x86_64" ]; then
        pkgs+=(lib32-gamemode lib32-mangohud)
    fi

    pacman_install_list "${pkgs[@]}"

    if command -v tailscale >/dev/null 2>&1 && [ "${HAS_SYSTEMD}" = true ]; then
        run_root systemctl enable --now tailscaled 2>/dev/null || true
    fi
}

install_cli_zypper() {
    echo "  [+] ZYPPER: actualizando repositorios..."
    run_root zypper --non-interactive --gpg-auto-import-keys refresh || true

    local pkgs=(
        curl wget git gh jq ripgrep fd tree rsync fzf bat zoxide
        htop btop tmux zsh zip unzip tar xz zstd 7zip
        gcc gcc-c++ make ca-certificates gpg2 openssl openssh
        fastfetch alacritty ffmpeg mpv vlc gamemode mangohud gamescope
        vulkan-tools android-tools java-21-openjdk-devel
        python3 python3-pip flatpak libfuse2
    )
    zypper_install_list "${pkgs[@]}"
}

install_cli_immutable() {
    echo "  [i] Sistema inmutable detectado (${DISTRO_PRETTY})."
    if command -v brew >/dev/null 2>&1; then
        export HOMEBREW_NO_AUTO_UPDATE=1
        export HOMEBREW_NO_ENV_HINTS=1
        local installed
        installed="$(brew list --formula 2>/dev/null || true)"
        local to_install=()
        local pkg
        for pkg in git gh jq ripgrep fd fzf bat zoxide tree btop htop tmux fastfetch alacritty; do
            if [[ $'\n'"${installed}"$'\n' != *$'\n'"${pkg}"$'\n'* ]]; then
                to_install+=("$pkg")
            fi
        done
        if [ ${#to_install[@]} -gt 0 ]; then
            echo "  [+] Homebrew: instalando ${to_install[*]}..."
            brew install "${to_install[@]}" 2>/dev/null || true
        else
            echo "  [✓] Herramientas CLI de Homebrew ya instaladas."
        fi
    fi
}

install_essential_cli() {
    detect_platform
    echo "  Plataforma : ${DISTRO_PRETTY} (${ARCH})"
    echo "  Gestor     : ${PKG_MGR} (inmutable: ${IS_IMMUTABLE}, contenedor: ${IN_CONTAINER})"

    case "${PKG_MGR}" in
        immutable) install_cli_immutable ;;
        apt)       install_cli_debian ;;
        dnf)       install_cli_fedora ;;
        pacman)    install_cli_arch ;;
        zypper)    install_cli_zypper ;;
        *)
            echo "  [!] No se detectó un gestor de paquetes soportado (apt/dnf/pacman/zypper)."
            ;;
    esac
}
