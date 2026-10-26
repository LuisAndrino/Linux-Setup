#!/usr/bin/env bash
# ==============================================================================
# install-1password.sh - Instalador de 1Password Desktop y 1Password CLI ('op')
# ==============================================================================
# Compatible con: Ubuntu, Debian, Fedora, Arch Linux, openSUSE, Bazzite, SteamOS
# 1. Instala la aplicación de escritorio 1Password (nativa o Flatpak oficial)
# 2. Instala la herramienta de línea de comandos 1Password CLI ('op') en ~/.local/bin
# ==============================================================================
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"
export PATH="${BIN_DIR}:${PATH}"

echo "=========================================================="
echo "    Instalación de 1Password Desktop y CLI ('op')         "
echo "=========================================================="

# -----------------------------------------------------------------------------
# 1. Instalar 1Password Desktop (GUI)
# -----------------------------------------------------------------------------
echo "[1/2] Verificando 1Password Desktop..."

INSTALLED_DESKTOP=false

if command -v 1password >/dev/null 2>&1; then
    echo "  [✓] 1Password Desktop ya está instalado en el sistema ($(command -v 1password))."
    INSTALLED_DESKTOP=true
elif flatpak info com.onepassword.OnePassword >/dev/null 2>&1; then
    echo "  [✓] 1Password ya está instalado mediante Flatpak."
    INSTALLED_DESKTOP=true
fi

if [ "$INSTALLED_DESKTOP" = false ]; then
    IS_IMMUTABLE=false
    DISTRO_ID="unknown"
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        if [ "${ID:-}" = "bazzite" ] || command -v rpm-ostree >/dev/null 2>&1 || [ -f /etc/steamos-release ]; then
            IS_IMMUTABLE=true
        fi
    fi

    if [ "$IS_IMMUTABLE" = true ]; then
        echo "  [+] Sistema inmutable detectado (${DISTRO_ID}). Instalando 1Password Flatpak oficial..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
        flatpak install -y --noninteractive flathub com.onepassword.OnePassword || true
        INSTALLED_DESKTOP=true
    else
        case "${DISTRO_ID}" in
            fedora|rhel|centos|rocky|alma)
                echo "  [DNF] Configurando repositorio oficial de 1Password..."
                sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc 2>/dev/null || true
                sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
                sudo dnf install -y 1password 1password-cli 2>/dev/null || true
                INSTALLED_DESKTOP=true
                ;;

            ubuntu|pop|mint|debian|kali|zorin)
                echo "  [APT] Configurando repositorio oficial de 1Password..."
                sudo install -d -m 0755 /usr/share/keyrings
                curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/1password-archive-keyring.gpg
                echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
                sudo apt-get update -y
                sudo apt-get install -y 1password 1password-cli 2>/dev/null || true
                INSTALLED_DESKTOP=true
                ;;

            arch|manjaro|endeavouros|garuda)
                echo "  [PACMAN] Instalando 1Password en Arch..."
                if command -v paru >/dev/null 2>&1; then
                    paru -S --needed --noconfirm 1password 1password-cli || true
                    INSTALLED_DESKTOP=true
                elif command -v yay >/dev/null 2>&1; then
                    yay -S --needed --noconfirm 1password 1password-cli || true
                    INSTALLED_DESKTOP=true
                fi
                ;;

            *)
                echo "  [+] Instalando 1Password vía Flatpak..."
                flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
                flatpak install -y --noninteractive flathub com.onepassword.OnePassword || true
                INSTALLED_DESKTOP=true
                ;;
        esac
    fi
fi

# -----------------------------------------------------------------------------
# 2. Instalar 1Password CLI ('op')
# -----------------------------------------------------------------------------
echo "[2/2] Verificando 1Password CLI ('op')..."

if command -v op >/dev/null 2>&1 || [ -f "${BIN_DIR}/op" ]; then
    echo "  [✓] 1Password CLI ya está disponible ($(op --version 2>/dev/null || echo 'en ruta'))."
else
    echo "  -> Descargando 1Password CLI oficial..."
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        OP_ARCH="amd64"
    elif [ "$ARCH" = "aarch64" ]; then
        OP_ARCH="arm64"
    else
        OP_ARCH="386"
    fi

    TMP_OP="/tmp/op_download"
    mkdir -p "${TMP_OP}"
    OP_VERSION="v2.30.0"
    if curl -sLo "${TMP_OP}/op.zip" "https://cache.agilebits.com/dist/1P/op2/pkg/${OP_VERSION}/op_linux_${OP_ARCH}_${OP_VERSION}.zip"; then
        unzip -q -o "${TMP_OP}/op.zip" -d "${TMP_OP}"
        if [ -f "${TMP_OP}/op" ]; then
            install -m 755 "${TMP_OP}/op" "${BIN_DIR}/op"
            rm -rf "${TMP_OP}"
            echo "  [✓] 1Password CLI instalado exitosamente en ${BIN_DIR}/op."
        fi
    fi
fi

echo ""
echo "=========================================================="
echo " [✓] ¡1Password Desktop y CLI ('op') listos para usar!"
echo "     - Interfaz gráfica: Busca '1Password' en tus aplicaciones"
echo "     - Terminal CLI: Escribe 'op signin' para autenticarte"
echo "=========================================================="
