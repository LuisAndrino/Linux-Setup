#!/usr/bin/env bash
# ==============================================================================
# install-powershell.sh - Instalador de Microsoft PowerShell (pwsh) en Linux
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          Instalación de PowerShell (pwsh)                "
echo "=========================================================="

if command -v pwsh >/dev/null 2>&1; then
    echo "[✓] PowerShell ya está instalado en el sistema ($(pwsh --version))."
    exit 0
fi

# Detectar gestor y sistema
echo "[+] Intentando instalar PowerShell mediante el gestor del sistema..."

INSTALLED=false

if command -v apt-get >/dev/null 2>&1; then
    # Si el repo de Microsoft ya fue añadido (por VS Code o setup.sh)
    if sudo apt-get install -y powershell 2>/dev/null; then
        INSTALLED=true
    fi
elif command -v dnf >/dev/null 2>&1; then
    if sudo dnf install -y powershell 2>/dev/null; then
        INSTALLED=true
    fi
elif command -v pacman >/dev/null 2>&1; then
    if sudo pacman -S --needed --noconfirm powershell 2>/dev/null; then
        INSTALLED=true
    elif command -v yay >/dev/null 2>&1 && yay -S --needed --noconfirm powershell-bin 2>/dev/null; then
        INSTALLED=true
    fi
fi

if [ "$INSTALLED" = false ]; then
    echo "[+] Usando el instalador oficial de Microsoft para Linux (aka.ms/install-powershell.sh)..."
    if curl -fsSL https://aka.ms/install-powershell.sh | bash 2>/dev/null; then
        INSTALLED=true
    fi
fi

# Respaldo portable en ~/.local/share/powershell si los anteriores fallaron
if [ "$INSTALLED" = false ] && ! command -v pwsh >/dev/null 2>&1; then
    echo "[+] Descargando binario portable oficial de PowerShell desde GitHub..."
    PWSH_DIR="${HOME}/.local/share/powershell"
    BIN_DIR="${HOME}/.local/bin"
    mkdir -p "${PWSH_DIR}" "${BIN_DIR}"

    LATEST_TAG=$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | grep '"tag_name":' | head -n1 | cut -d'"' -f4 || echo "v7.4.5")
    VERSION_NUM="${LATEST_TAG#v}"
    TAR_URL="https://github.com/PowerShell/PowerShell/releases/download/${LATEST_TAG}/powershell-${VERSION_NUM}-linux-x64.tar.gz"

    echo "    Descargando ${TAR_URL}..."
    curl -fL -o /tmp/powershell.tar.gz "${TAR_URL}"
    tar -xzf /tmp/powershell.tar.gz -C "${PWSH_DIR}"
    rm -f /tmp/powershell.tar.gz
    chmod +x "${PWSH_DIR}/pwsh"
    ln -sf "${PWSH_DIR}/pwsh" "${BIN_DIR}/pwsh"
    echo "[✓] PowerShell portable instalado en ${PWSH_DIR}/pwsh"
fi

if command -v pwsh >/dev/null 2>&1 || [ -f "${HOME}/.local/bin/pwsh" ]; then
    echo "[✓] PowerShell instalado exitosamente. Puedes iniciarlo escribiendo: pwsh"
else
    echo "[!] Advertencia: No se pudo verificar la instalación de pwsh."
fi
