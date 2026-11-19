#!/usr/bin/env bash
# ==============================================================================
# install-1password.sh - Instalador multi-distro de 1Password Desktop + CLI (op)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"

echo "=== 1Password (Desktop + CLI) ==="

# 1. 1Password Desktop
if command -v 1password >/dev/null 2>&1 || (command -v flatpak >/dev/null 2>&1 && flatpak info com.onepassword.OnePassword >/dev/null 2>&1); then
    echo "  [✓] 1Password Desktop ya está instalado."
else
    case "${PKG_MGR}" in
        immutable)
            flatpak_install_safe com.onepassword.OnePassword || true
            ;;
        apt)
            if [ "${DEB_ARCH}" = "amd64" ]; then
                echo "  [+] Configurando repositorio oficial de 1Password (APT)..."
                run_root install -d -m 0755 /usr/share/keyrings
                if safe_download "https://downloads.1password.com/linux/keys/1password.asc" "/tmp/1password.asc" 30; then
                    gpg --dearmor --batch --yes -o /tmp/1password.gpg /tmp/1password.asc
                    run_root install -m 0644 /tmp/1password.gpg /usr/share/keyrings/1password-archive-keyring.gpg
                    rm -f /tmp/1password.asc /tmp/1password.gpg
                    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main" | \
                        run_root tee /etc/apt/sources.list.d/1password.list >/dev/null
                    apt_update_safe
                    apt_install_list 1password 1password-cli
                fi
            else
                flatpak_install_safe com.onepassword.OnePassword || true
            fi
            ;;
        dnf)
            echo "  [+] Configurando repositorio oficial de 1Password (DNF)..."
            run_root rpm --import https://downloads.1password.com/linux/keys/1password.asc 2>/dev/null || true
            run_root tee /etc/yum.repos.d/1password.repo >/dev/null << 'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF
            dnf_install_list 1password 1password-cli
            ;;
        pacman)
            if command -v paru >/dev/null 2>&1 && [ "${EUID:-$(id -u)}" -ne 0 ]; then
                paru -S --needed --noconfirm 1password 1password-cli || true
            elif command -v yay >/dev/null 2>&1 && [ "${EUID:-$(id -u)}" -ne 0 ]; then
                yay -S --needed --noconfirm 1password 1password-cli || true
            else
                flatpak_install_safe com.onepassword.OnePassword || true
            fi
            ;;
        zypper)
            echo "  [+] Configurando repositorio oficial de 1Password (Zypper)..."
            run_root rpm --import https://downloads.1password.com/linux/keys/1password.asc 2>/dev/null || true
            run_root tee /etc/zypp/repos.d/1password.repo >/dev/null << 'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF
            run_root zypper --non-interactive --gpg-auto-import-keys refresh || true
            zypper_install_list 1password 1password-cli
            ;;
    esac
fi

# 2. 1Password CLI ('op') binario oficial como respaldo universal
if command -v op >/dev/null 2>&1 || [ -x "${BIN_DIR}/op" ]; then
    echo "  [✓] 1Password CLI ('op') ya está disponible."
else
    echo "  [+] Descargando 1Password CLI ('op')..."
    OP_VERSION="v2.30.0"
    TMP_OP="/tmp/op_download_$$"
    mkdir -p "${TMP_OP}"
    if safe_download "https://cache.agilebits.com/dist/1P/op2/pkg/${OP_VERSION}/op_linux_${DEB_ARCH}_${OP_VERSION}.zip" "${TMP_OP}/op.zip" 90; then
        unzip -q -o "${TMP_OP}/op.zip" -d "${TMP_OP}" 2>/dev/null || true
        if [ -f "${TMP_OP}/op" ]; then
            install -m 755 "${TMP_OP}/op" "${BIN_DIR}/op"
            echo "  [✓] 1Password CLI instalado en ${BIN_DIR}/op."
        fi
    else
        echo "  [!] No se pudo descargar 1Password CLI."
    fi
    rm -rf "${TMP_OP}"
fi
