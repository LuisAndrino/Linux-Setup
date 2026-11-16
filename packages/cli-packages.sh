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
    local apt_opts=(-y -o DPkg::Lock::Timeout=120)

    # Recuperar estado de dpkg por si hubo una ejecución interrumpida previa
    sudo dpkg --configure -a >/dev/null 2>&1 || true

    echo "==> [APT] Actualizando índices base de paquetes..."
    sudo apt-get "${apt_opts[@]}" update -qq || sudo apt-get update || true

    # 1. Instalar primero pre-requisitos mínimos para repositorios externos y PPAs
    local bootstrap_pkgs=(curl wget ca-certificates gnupg apt-transport-https debconf-utils)
    if grep -qiE '^ID=ubuntu|^ID_LIKE=.*ubuntu' /etc/os-release 2>/dev/null; then
        bootstrap_pkgs+=(software-properties-common)
    fi
    sudo DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" install -qq "${bootstrap_pkgs[@]}" || \
        sudo DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" install "${bootstrap_pkgs[@]}" || true

    # 2. Habilitar repositorios universe/multiverse en Ubuntu (necesario para steam-installer, gamescope, mangohud, fastfetch, alacritty, etc.)
    if grep -qiE '^ID=ubuntu|^ID_LIKE=.*ubuntu' /etc/os-release 2>/dev/null; then
        if command -v add-apt-repository >/dev/null 2>&1; then
            sudo add-apt-repository -y universe >/dev/null 2>&1 || true
            sudo add-apt-repository -y multiverse >/dev/null 2>&1 || true
        fi
    fi

    # 3. Habilitar i386 (multilib) para Steam / Wine / Proton
    sudo dpkg --add-architecture i386 2>/dev/null || true

    echo "==> [APT] Actualizando índices tras habilitar universe/multiverse/i386..."
    sudo apt-get "${apt_opts[@]}" update -qq || sudo apt-get update || true

    echo "==> [APT] Verificando disponibilidad e instalando pre-requisitos, CLI, dev y gaming..."
    local candidate_pkgs=(
        curl wget git gh jq ripgrep tree rsync fzf zoxide fd-find
        htop btop tmux zsh zip unzip tar xz-utils zstd p7zip-full bat
        build-essential ca-certificates gnupg apt-transport-https debconf-utils
        openssh-client openssh-server alacritty
        ffmpeg mpv vlc gamemode mangohud gamescope
        vulkan-tools mesa-vulkan-drivers
        adb fastboot python3 python3-pip flatpak
    )

    # Solo incluir plugin de GNOME Software si ya existe gnome-software (evita arrastrarlo en Kubuntu/Server)
    if command -v gnome-software >/dev/null 2>&1; then
        candidate_pkgs+=(gnome-software-plugin-flatpak)
    fi

    # FUSE2 para ejecutar AppImages en Ubuntu 22.04+ / 24.04+ (Antigravity, OpenBot, Grok Bot, RecompLauncher, etc.)
    if apt-cache show libfuse2t64 >/dev/null 2>&1; then
        candidate_pkgs+=(libfuse2t64)
    elif apt-cache show libfuse2 >/dev/null 2>&1; then
        candidate_pkgs+=(libfuse2)
    fi

    # Elegir JDK 21 si existe, si no default-jdk (compatible con Ubuntu 22.04/24.04 y Debian 12)
    if apt-cache show openjdk-21-jdk >/dev/null 2>&1; then
        candidate_pkgs+=(openjdk-21-jdk)
    elif apt-cache show default-jdk >/dev/null 2>&1; then
        candidate_pkgs+=(default-jdk)
    fi

    # Elegir fastfetch si existe en la versión actual, si no neofetch
    if apt-cache show fastfetch >/dev/null 2>&1; then
        candidate_pkgs+=(fastfetch)
    elif apt-cache show neofetch >/dev/null 2>&1; then
        candidate_pkgs+=(neofetch)
    fi

    # Filtrar usando apt-cache show (evita paquetes virtuales y evita pipe >64KB con SIGPIPE bajo pipefail)
    local valid_pkgs=()
    for pkg in "${candidate_pkgs[@]}"; do
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            valid_pkgs+=("$pkg")
        else
            echo "  [!] Paquete '$pkg' sin candidato en esta versión de Debian/Ubuntu, omitiendo."
        fi
    done

    if [ "${#valid_pkgs[@]}" -gt 0 ]; then
        echo "  [+] Instalando ${#valid_pkgs[@]} paquetes vía APT..."
        if ! sudo DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" install -qq "${valid_pkgs[@]}"; then
            echo "  [!] Fallo en lote APT; reparando dependencias e instalando paquete por paquete..."
            sudo DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" install -f || true
            for pkg in "${valid_pkgs[@]}"; do
                sudo DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" install -qq "$pkg" || \
                    echo "  [!] No se pudo instalar '$pkg'"
            done
        fi
    fi

    # En Debian/Ubuntu bat se llama 'batcat' y fd se llama 'fdfind'; crear symlinks en ~/.local/bin
    mkdir -p "${HOME}/.local/bin"
    if command -v batcat >/dev/null 2>&1 && [ ! -e "${HOME}/.local/bin/bat" ]; then
        ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
    fi
    if command -v fdfind >/dev/null 2>&1 && [ ! -e "${HOME}/.local/bin/fd" ]; then
        ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
    fi
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
    # Acelerar Pacman habilitando ParallelDownloads = 10, Color y [multilib] (Steam/32-bit)
    if [ -f /etc/pacman.conf ]; then
        sudo sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf 2>/dev/null || true
        sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf 2>/dev/null || true
        if grep -qE '^#\[multilib\]' /etc/pacman.conf; then
            echo "==> [PACMAN] Habilitando repositorio [multilib] en /etc/pacman.conf..."
            sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf 2>/dev/null || true
        fi
    fi

    echo "==> [PACMAN] Sincronizando bases de datos..."
    sudo pacman -Sy --noconfirm

    # Lista validada con nombres oficiales reales de Arch Linux (7zip reemplaza p7zip; sin paquetes Debian/Fedora)
    local desired_pkgs=(
        curl wget git github-cli jq ripgrep fd tree rsync fzf bat zoxide
        htop btop tmux zsh zip unzip 7zip zstd
        base-devel openssh fastfetch alacritty
        ffmpeg mpv vlc gamemode mangohud gamescope
        android-tools jdk-openjdk python python-pip
        flatpak firefox code tailscale
        steam lib32-gamemode lib32-mangohud
    )

    # Filtrar contra pacman -Slq para que ningún paquete inexistente aborte toda la transacción
    local available_pkgs
    available_pkgs=$(pacman -Slq 2>/dev/null || true)
    local valid_pkgs=()
    local skipped_pkgs=()
    for pkg in "${desired_pkgs[@]}"; do
        if [[ $'\n'"${available_pkgs}"$'\n' == *$'\n'"${pkg}"$'\n'* ]]; then
            valid_pkgs+=("${pkg}")
        else
            skipped_pkgs+=("${pkg}")
        fi
    done

    if [ ${#skipped_pkgs[@]} -gt 0 ]; then
        echo "  [i] Omitiendo paquetes no presentes en tus repos habilitados: ${skipped_pkgs[*]}"
    fi

    if [ ${#valid_pkgs[@]} -gt 0 ]; then
        echo "==> [PACMAN] Actualizando sistema e instalando ${#valid_pkgs[@]} paquetes en lote único (ParallelDownloads=10)..."
        if ! sudo pacman -Syu --noconfirm --needed "${valid_pkgs[@]}"; then
            echo "[!] Reintentando actualización e instalación individual de paquetes restantes..."
            sudo pacman -Syu --noconfirm || true
            for pkg in "${valid_pkgs[@]}"; do
                sudo pacman -S --noconfirm --needed "${pkg}" || echo "  [!] No se pudo instalar ${pkg}"
            done
        fi
    fi

    # Asegurar servicio tailscaled habilitado si se instaló tailscale vía pacman
    if command -v tailscale >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable --now tailscaled 2>/dev/null || true
    fi
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
