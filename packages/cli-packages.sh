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
    export DEBIAN_FRONTEND=noninteractive
    if [ -z "$(find /var/lib/apt/lists -maxdepth 1 -mmin -15 2>/dev/null)" ]; then
        echo "==> [APT] Actualizando índices de paquetes..."
        sudo apt-get update -qq
    else
        echo "==> [APT] Índices actualizados recientemente. Omitiendo apt update."
    fi
    echo "==> [APT] Instalando paquetes CLI, desarrollo, multimedia y gaming..."
    sudo apt-get install -y -qq \
        curl wget git gh jq ripgrep tree rsync fzf zoxide \
        htop btop tmux zsh zip unzip p7zip-full bat \
        build-essential ca-certificates gnupg \
        openssh-client openssh-server alacritty \
        ffmpeg mpv vlc gamemode mangohud gamescope \
        adb fastboot openjdk-21-jdk || true

    # En Debian/Ubuntu bat se llama 'batcat', crear alias/symlink a ~/.local/bin/bat
    if command -v batcat >/dev/null 2>&1 && [ ! -f "${HOME}/.local/bin/bat" ]; then
        mkdir -p "${HOME}/.local/bin"
        ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
    fi

    sudo apt-get install -y -qq fastfetch 2>/dev/null || sudo apt-get install -y -qq neofetch 2>/dev/null || true
    sudo apt-get install -y -qq gnome-software-plugin-flatpak 2>/dev/null || true
}

install_cli_fedora() {
    # Acelerar DNF habilitando descargas paralelas (10 hilos) y fastestmirror
    if [ -f /etc/dnf/dnf.conf ]; then
        if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
            echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf >/dev/null 2>&1 || true
        fi
        if ! grep -q "fastestmirror" /etc/dnf/dnf.conf; then
            echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf >/dev/null 2>&1 || true
        fi
    fi

    echo "==> [DNF] Instalando paquetes CLI, desarrollo, multimedia y gaming (10 descargas paralelas)..."
    sudo dnf install -y --skip-unavailable \
        curl wget git gh jq ripgrep tree rsync fzf bat zoxide \
        htop btop tmux zsh zip unzip p7zip p7zip-plugins \
        gcc gcc-c++ make automake autoconf \
        openssh-clients openssh-server fastfetch alacritty \
        ffmpeg mpv vlc gamemode mangohud gamescope \
        android-tools java-21-openjdk-devel plasma-discover-flatpak-backend || true
}

install_cli_arch() {
    # Acelerar Pacman habilitando ParallelDownloads = 10
    if [ -f /etc/pacman.conf ]; then
        sudo sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf 2>/dev/null || true
    fi

    echo "==> [PACMAN] Actualizando e instalando paquetes CLI, desarrollo, multimedia y gaming..."
    sudo pacman -Syu --noconfirm --needed \
        curl wget git github-cli jq ripgrep tree rsync fzf bat zoxide \
        htop btop tmux zsh zip unzip p7zip \
        base-devel openssh fastfetch alacritty \
        ffmpeg mpv vlc gamemode mangohud gamescope \
        android-tools jdk-openjdk plasma-discover-flatpak-backend || true

    # Si multilib está habilitado, instalar versiones de 32 bits para juegos clásicos
    sudo pacman -S --needed --noconfirm lib32-gamemode lib32-mangohud 2>/dev/null || true
}

install_cli_zypper() {
    echo "==> [ZYPPER] Instalando paquetes CLI, desarrollo, multimedia y gaming..."
    sudo zypper --non-interactive install \
        curl wget git gh jq ripgrep tree rsync fzf bat zoxide \
        htop btop tmux zsh zip unzip p7zip \
        gcc gcc-c++ make openssh fastfetch alacritty \
        ffmpeg mpv vlc gamemode mangohud gamescope \
        android-tools java-21-openjdk-devel || true
}

install_cli_immutable() {
    echo "==> [Sistema Inmutable Detectado] (${DISTRO_ID})"
    if command -v brew >/dev/null 2>&1; then
        export HOMEBREW_NO_AUTO_UPDATE=1
        export HOMEBREW_NO_ENV_HINTS=1
        local installed_formulae
        installed_formulae=$(brew list --formula 2>/dev/null || true)
        local to_install=()
        for pkg in git gh jq ripgrep fzf bat zoxide tree btop htop tmux fastfetch alacritty; do
            if ! echo "$installed_formulae" | grep -qx "$pkg"; then
                to_install+=("$pkg")
            fi
        done
        if [ ${#to_install[@]} -gt 0 ]; then
            echo "==> Instalando herramientas CLI faltantes vía Homebrew: ${to_install[*]}..."
            brew install "${to_install[@]}" 2>/dev/null || true
        else
            echo "  [✓] Todas las herramientas CLI de Homebrew ya están instaladas."
        fi
        if ! brew list --cask 2>/dev/null | grep -qx "android-platform-tools"; then
            brew install --cask android-platform-tools 2>/dev/null || true
        fi
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
