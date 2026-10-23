#!/usr/bin/env bash
# ==============================================================================
# cli-packages.sh - Mapeo y funciones de instalación para paquetes CLI, Gaming y Multimedia
# ==============================================================================
# Compatible con: Ubuntu, Debian, Fedora, Arch Linux, openSUSE, Bazzite, SteamOS
# ==============================================================================

detect_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
    else
        DISTRO_ID="unknown"
        DISTRO_ID_LIKE=""
    fi

    # Detectar sistemas inmutables basados en OSTree (Bazzite, Silverblue, SteamOS)
    IS_IMMUTABLE=false
    if command -v rpm-ostree >/dev/null 2>&1 || [ -f /etc/steamos-release ] || [ "${DISTRO_ID}" = "bazzite" ]; then
        IS_IMMUTABLE=true
    fi
}

install_cli_debian() {
    echo "==> [APT] Actualizando índices de paquetes..."
    sudo apt update -y
    echo "==> [APT] Instalando paquetes CLI, desarrollo, multimedia y gaming..."
    sudo apt install -y \
        curl wget git gh jq ripgrep tree rsync fzf zoxide \
        htop btop tmux zsh zip unzip p7zip-full bat \
        build-essential ca-certificates gnupg \
        openssh-client openssh-server alacritty \
        ffmpeg mpv vlc gamemode mangohud gamescope || true

    # En Debian/Ubuntu bat se llama 'batcat', crear alias/symlink a ~/.local/bin/bat
    if command -v batcat >/dev/null 2>&1 && [ ! -f "${HOME}/.local/bin/bat" ]; then
        mkdir -p "${HOME}/.local/bin"
        ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
    fi

    sudo apt install -y fastfetch 2>/dev/null || sudo apt install -y neofetch 2>/dev/null || true
    sudo apt install -y gnome-software-plugin-flatpak 2>/dev/null || true
}

install_cli_fedora() {
    echo "==> [DNF] Instalando paquetes CLI, desarrollo, multimedia y gaming..."
    sudo dnf install -y \
        curl wget git gh jq ripgrep tree rsync fzf bat zoxide \
        htop btop tmux zsh zip unzip p7zip p7zip-plugins \
        gcc gcc-c++ make automake autoconf \
        openssh-clients openssh-server fastfetch alacritty \
        ffmpeg mpv vlc gamemode mangohud gamescope || true

    sudo dnf install -y plasma-discover-flatpak-backend 2>/dev/null || true
}

install_cli_arch() {
    echo "==> [PACMAN] Actualizando e instalando paquetes CLI, desarrollo, multimedia y gaming..."
    sudo pacman -Syu --noconfirm --needed \
        curl wget git github-cli jq ripgrep tree rsync fzf bat zoxide \
        htop btop tmux zsh zip unzip p7zip \
        base-devel openssh fastfetch alacritty \
        ffmpeg mpv vlc gamemode mangohud gamescope || true

    sudo pacman -S --needed --noconfirm plasma-discover-flatpak-backend 2>/dev/null || true

    # Si multilib está habilitado, instalar versiones de 32 bits para juegos clásicos
    sudo pacman -S --needed --noconfirm lib32-gamemode lib32-mangohud 2>/dev/null || true
}

install_cli_zypper() {
    echo "==> [ZYPPER] Instalando paquetes CLI, desarrollo, multimedia y gaming..."
    sudo zypper --non-interactive install \
        curl wget git gh jq ripgrep tree rsync fzf bat zoxide \
        htop btop tmux zsh zip unzip p7zip \
        gcc gcc-c++ make openssh fastfetch alacritty \
        ffmpeg mpv vlc gamemode mangohud gamescope || true
}

install_cli_immutable() {
    echo "==> [Sistema Inmutable Detectado] (${DISTRO_ID})"
    if command -v brew >/dev/null 2>&1; then
        echo "==> Instalando herramientas CLI mediante Homebrew..."
        brew install git gh jq ripgrep fzf bat zoxide tree btop htop tmux fastfetch alacritty 2>/dev/null || true
    fi
}

install_essential_cli() {
    detect_distro

    echo "=========================================================="
    echo " Distribución detectada: ${DISTRO_ID} (${DISTRO_ID_LIKE})"
    echo " Modo inmutable: ${IS_IMMUTABLE}"
    echo "=========================================================="

    if [ "${IS_IMMUTABLE}" = true ]; then
        install_cli_immutable
        return 0
    fi

    case "${DISTRO_ID}" in
        ubuntu|debian|pop|mint|elementary|zorin|kali)
            install_cli_debian
            ;;
        fedora|rhel|centos|rocky|alma)
            install_cli_fedora
            ;;
        arch|manjaro|endeavouros|artix|garuda)
            install_cli_arch
            ;;
        opensuse*|suse|sles)
            install_cli_zypper
            ;;
        *)
            # Fallback usando ID_LIKE
            if echo "${DISTRO_ID_LIKE}" | grep -qE "debian|ubuntu"; then
                install_cli_debian
            elif echo "${DISTRO_ID_LIKE}" | grep -qE "fedora|rhel"; then
                install_cli_fedora
            elif echo "${DISTRO_ID_LIKE}" | grep -q "arch"; then
                install_cli_arch
            elif echo "${DISTRO_ID_LIKE}" | grep -q "suse"; then
                install_cli_zypper
            else
                echo "[!] Distribución no reconocida directamente. Intentando comandos genéricos..."
                if command -v apt >/dev/null 2>&1; then install_cli_debian
                elif command -v dnf >/dev/null 2>&1; then install_cli_fedora
                elif command -v pacman >/dev/null 2>&1; then install_cli_arch
                elif command -v zypper >/dev/null 2>&1; then install_cli_zypper
                fi
            fi
            ;;
    esac
}
