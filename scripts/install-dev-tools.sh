#!/usr/bin/env bash
# ==============================================================================
# install-dev-tools.sh - Instalador de OpenJDK 21, Lazygit y Mise
# ==============================================================================
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"

echo "=========================================================="
echo "    Instalación de Herramientas de Desarrollo (Java, Git, Mise)"
echo "=========================================================="

# 1. Instalar OpenJDK 21 (Requerido para Apache NetBeans y Prism Launcher)
if command -v java >/dev/null 2>&1; then
    echo "[✓] Java ya está instalado ($(java -version 2>&1 | head -n1))."
else
    echo "[+] Instalando OpenJDK 21..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y && sudo apt-get install -y openjdk-21-jdk || true
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y java-21-openjdk-devel || true
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm jdk-openjdk || true
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install java-21-openjdk-devel || true
    elif command -v brew >/dev/null 2>&1; then
        brew install openjdk@21 || true
    fi
fi

# 2. Instalar Lazygit (Terminal UI ultra-rápida para Git)
if command -v lazygit >/dev/null 2>&1; then
    echo "[✓] Lazygit ya está instalado ($(lazygit --version 2>&1 | head -n1))."
else
    echo "[+] Instalando Lazygit..."
    INSTALLED_LAZYGIT=false

    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm lazygit 2>/dev/null && INSTALLED_LAZYGIT=true || true
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install lazygit 2>/dev/null && INSTALLED_LAZYGIT=true || true
    elif command -v brew >/dev/null 2>&1; then
        brew install lazygit 2>/dev/null && INSTALLED_LAZYGIT=true || true
    fi

    if [ "$INSTALLED_LAZYGIT" = false ]; then
        echo "[+] Descargando binario oficial de Lazygit desde GitHub..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "0.44.1")
        curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit 2>/dev/null || true
        if [ -f /tmp/lazygit ]; then
            install -m 755 /tmp/lazygit "${BIN_DIR}/lazygit"
            rm -f /tmp/lazygit /tmp/lazygit.tar.gz
            echo "[✓] Lazygit instalado en ${BIN_DIR}/lazygit."
        fi
    fi
fi

# 3. Instalar Mise (Gestor de runtimes para Node.js, Python, Java, Rust)
if command -v mise >/dev/null 2>&1 || [ -f "${BIN_DIR}/mise" ]; then
    echo "[✓] Mise ya está instalado."
else
    echo "[+] Instalando Mise (Gestor políglota de entornos de desarrollo)..."
    if curl -fsSL https://mise.run | sh; then
        echo "[✓] Mise instalado exitosamente en ${BIN_DIR}/mise."
    fi
fi

echo ""
echo "=========================================================="
echo " [✓] Herramientas de desarrollo listas:"
echo "     - Java OpenJDK: $(command -v java 2>/dev/null || echo 'en ruta')"
echo "     - Lazygit: Escribe 'lazygit' dentro de cualquier repo"
echo "     - Mise: Escribe 'mise' para gestionar Node/Python/Java"
echo "=========================================================="
