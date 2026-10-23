#!/usr/bin/env bash
# ==============================================================================
# cli-packages.sh - Mapeo y funciones de instalación para paquetes CLI y Gaming
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
    echo "==> [APT] Instalando paquetes CLI, terminal y optimizaciones de gaming..."
    sudo apt install -y \
        curl wget git gh jq ripgrep tree rsync \
        htop btop tmux zsh zip unzip p7zip-full \
        build-essential ca-certificates gnupg \
        openssh-client openssh-server alacritty \
        gamemode mangohud gamescope || true

    sudo apt install -y fastfetch 2>/dev/null || sudo apt install -y neofetch 2>/dev/null || true
}

install_cli_fedora() {
    echo "==> [DNF] Instalando paquetes CLI, terminal y optimizaciones de gaming..."
    sudo dnf install -y \
        curl wget git gh jq ripgrep tree rsync \
        htop btop tmux zsh zip unzip p7zip p7zip-plugins \
        gcc gcc-c++ make automake autoconf \
        openssh-clients openssh-server fastfetch alacritty \
        gamemode mangohud gamescope || true
}

install_cli_arch() {
    echo "==> [PACMAN] Actualizando e instalando paquetes CLI, terminal y gaming..."
    sudo pacman -Syu --noconfirm --needed \
        curl wget git github-cli jq ripgrep tree rsync \
        htop btop tmux zsh zip unzip p7zip \
        base-devel openssh fastfetch alacritty \
        gamemode mangohud gamescope || true

    # Si multilib está habilitado, instalar versiones de 32 bits para juegos clásicos
    sudo pacman -S --needed --noconfirm lib32-gamemode lib32-mangohud 2>/dev/null || true
}

install_cli_zypper() {
    echo "==> [ZYPPER] Instalando paquetes CLI, terminal y gaming..."
    sudo zypper --non-interactive install \
        curl wget git gh jq ripgrep tree rsync \
        htop btop tmux zsh zip unzip p7zip \
        gcc gcc-c++ make openssh fastfetch alacritty \
        gamemode mangohud gamescope || true
}

install_cli_immutable() {
    echo "==> [Sistema Inmutable Detectado] (${DISTRO_ID})"
    if command -v brew >/dev/null 2>&1; then
        echo "==> Instalando herramientas CLI mediante Homebrew..."
        brew install git gh jq ripgrep tree btop htop tmux fastfetch alacritty 2>/dev/null || true
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
        arch|manjaro|endeavouros|garuda|artix)
            install_cli_arch
            ;;
        opensuse*|suse)
            install_cli_zypper
            ;;
        *)
            if [[ "${DISTRO_ID_LIKE}" =~ (ubuntu|debian) ]]; then
                install_cli_debian
            elif [[ "${DISTRO_ID_LIKE}" =~ (fedora|rhel) ]]; then
                install_cli_fedora
            elif [[ "${DISTRO_ID_LIKE}" =~ arch ]]; then
                install_cli_arch
            elif [[ "${DISTRO_ID_LIKE}" =~ suse ]]; then
                install_cli_zypper
            else
                if command -v apt >/dev/null 2>&1; then
                    install_cli_debian
                elif command -v dnf >/dev/null 2>&1; then
                    install_cli_fedora
                elif command -v pacman >/dev/null 2>&1; then
                    install_cli_arch
                elif command -v zypper >/dev/null 2>&1; then
                    install_cli_zypper
                fi
            fi
            ;;
    esac
}
