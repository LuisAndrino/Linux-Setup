#!/usr/bin/env bash
# ==============================================================================
# install-dev-tools.sh - Instalador Integral de Herramientas de Desarrollo
# ==============================================================================
# Incluye:
# 1. Neovim Moderno (v0.10+ con configuración Lua)
# 2. Lazygit (Terminal UI para Git)
# 3. Mise (Gestor políglota de entornos: Node, Python, Rust, Go, Java)
# 4. Astral uv / uvx (Gestor ultra-rápido de Python)
# 5. Bun (Runtime JS/TS de alto rendimiento)
# 6. OpenJDK 21 (Java LTS)
# 7. GitHub CLI (gh)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"
export PATH="${BIN_DIR}:${PATH}"

echo "=========================================================="
echo "    Instalación de Suite de Desarrollo de Software        "
echo "=========================================================="

# 1. Neovim Moderno
echo "[1/6] Configurando Neovim..."
if [ -f "${SCRIPT_DIR}/install-neovim.sh" ]; then
    bash "${SCRIPT_DIR}/install-neovim.sh"
fi

# 2. OpenJDK 21 (Java LTS)
echo "[2/6] Verificando Java OpenJDK 21..."
if command -v java >/dev/null 2>&1; then
    echo "  [✓] Java ya está instalado ($(java -version 2>&1 | head -n1))."
else
    echo "  -> Instalando OpenJDK 21..."
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

# 3. Lazygit (Terminal UI para Git)
echo "[3/6] Verificando Lazygit..."
if command -v lazygit >/dev/null 2>&1; then
    echo "  [✓] Lazygit ya está instalado ($(lazygit --version 2>&1 | head -n1))."
else
    echo "  -> Instalando Lazygit..."
    INSTALLED_LAZYGIT=false
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm lazygit 2>/dev/null && INSTALLED_LAZYGIT=true || true
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install lazygit 2>/dev/null && INSTALLED_LAZYGIT=true || true
    elif command -v brew >/dev/null 2>&1; then
        brew install lazygit 2>/dev/null && INSTALLED_LAZYGIT=true || true
    fi

    if [ "$INSTALLED_LAZYGIT" = false ]; then
        echo "  -> Descargando binario oficial de Lazygit desde GitHub..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "0.44.1")
        curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit 2>/dev/null || true
        if [ -f /tmp/lazygit ]; then
            install -m 755 /tmp/lazygit "${BIN_DIR}/lazygit"
            rm -f /tmp/lazygit /tmp/lazygit.tar.gz
            echo "  [✓] Lazygit instalado en ${BIN_DIR}/lazygit."
        fi
    fi
fi

# 4. Mise (Gestor de runtimes: Node, Python, Java, Rust)
echo "[4/6] Verificando Mise..."
if command -v mise >/dev/null 2>&1 || [ -f "${BIN_DIR}/mise" ]; then
    echo "  [✓] Mise ya está instalado."
else
    echo "  -> Instalando Mise..."
    curl -fsSL https://mise.run | sh 2>/dev/null || true
fi

# 5. Astral uv (Python) y Bun (JS/TS)
echo "[5/6] Verificando runtimes rápidos (uv & Bun)..."
if ! command -v uv >/dev/null 2>&1 && [ ! -f "${BIN_DIR}/uv" ]; then
    echo "  -> Instalando Astral uv..."
    curl -LsSf https://astral.sh/uv/install.sh | env CARGO_HOME="${HOME}/.local" sh 2>/dev/null || true
fi

if ! command -v bun >/dev/null 2>&1 && [ ! -f "${HOME}/.bun/bin/bun" ]; then
    echo "  -> Instalando Bun..."
    curl -fsSL https://bun.sh/install | bash 2>/dev/null || true
fi

# 6. GitHub CLI (gh)
echo "[6/6] Verificando GitHub CLI (gh)..."
if command -v gh >/dev/null 2>&1; then
    echo "  [✓] GitHub CLI (gh) ya está disponible."
else
    echo "  -> Instalando GitHub CLI..."
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm github-cli 2>/dev/null || true
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y gh 2>/dev/null || true
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y gh 2>/dev/null || true
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install gh 2>/dev/null || true
    elif command -v brew >/dev/null 2>&1; then
        brew install gh 2>/dev/null || true
    fi
fi

# Asegurar variables de entorno y PATH en shells de usuario
for RC in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    if [ -f "$RC" ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"' "$RC"; then
            echo 'export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"' >> "$RC"
        fi
    fi
done

echo ""
echo "=========================================================="
echo " [✓] Suite de Desarrollo lista:"
echo "     - Neovim: 'nvim'"
echo "     - Lazygit: 'lazygit'"
echo "     - Mise: 'mise'"
echo "     - Astral uv: 'uv'"
echo "     - Bun: 'bun'"
echo "     - Java OpenJDK: $(command -v java 2>/dev/null || echo 'en ruta')"
echo "     - GitHub CLI: 'gh'"
echo "=========================================================="
