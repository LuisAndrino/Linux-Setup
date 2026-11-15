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

echo "  [+] Lanzando descargas en paralelo (Neovim, Lazygit, Mise, uv, Bun)..."

# 1. Neovim Moderno (Background)
(
    if [ -f "${SCRIPT_DIR}/install-neovim.sh" ]; then
        bash "${SCRIPT_DIR}/install-neovim.sh"
    fi
) &

# 2. Lazygit (Background)
(
    if ! command -v lazygit >/dev/null 2>&1; then
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' || echo "0.44.1")
        curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit 2>/dev/null || true
        if [ -f /tmp/lazygit ]; then
            install -m 755 /tmp/lazygit "${BIN_DIR}/lazygit"
            rm -f /tmp/lazygit /tmp/lazygit.tar.gz
            echo "  [✓] Lazygit instalado en ${BIN_DIR}/lazygit."
        fi
    else
        echo "  [✓] Lazygit ya está instalado."
    fi
) &

# 3. Mise (Background)
(
    if ! command -v mise >/dev/null 2>&1 && [ ! -f "${BIN_DIR}/mise" ]; then
        curl -fsSL https://mise.run | sh 2>/dev/null || true
        echo "  [✓] Mise instalado."
    else
        echo "  [✓] Mise ya está instalado."
    fi
) &

# 4. Astral uv (Background)
(
    if ! command -v uv >/dev/null 2>&1 && [ ! -f "${BIN_DIR}/uv" ]; then
        curl -LsSf https://astral.sh/uv/install.sh | env CARGO_HOME="${HOME}/.local" sh 2>/dev/null || true
        echo "  [✓] uv instalado."
    else
        echo "  [✓] uv ya está instalado."
    fi
) &

# 5. Bun (Background)
(
    if ! command -v bun >/dev/null 2>&1 && [ ! -f "${HOME}/.bun/bin/bun" ]; then
        curl -fsSL https://bun.sh/install | bash 2>/dev/null || true
        echo "  [✓] Bun instalado."
    else
        echo "  [✓] Bun ya está instalado."
    fi
) &

# 6. OpenJDK 21 y GitHub CLI (Primer plano en una sola transacción del gestor del sistema)
if ! command -v java >/dev/null 2>&1 || ! command -v gh >/dev/null 2>&1; then
    echo "  -> Verificando/Instalando OpenJDK 21 y GitHub CLI (gh)..."
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y --skip-unavailable java-21-openjdk-devel gh || true
    elif command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        if [ -z "$(find /var/lib/apt/lists -maxdepth 1 -mmin -15 2>/dev/null)" ]; then
            sudo apt-get update -qq || true
        fi
        apt_pkgs=()
        if ! command -v java >/dev/null 2>&1; then
            if apt-cache show openjdk-21-jdk >/dev/null 2>&1; then
                apt_pkgs+=("openjdk-21-jdk")
            elif apt-cache show default-jdk >/dev/null 2>&1; then
                apt_pkgs+=("default-jdk")
            fi
        fi
        if ! command -v gh >/dev/null 2>&1 && apt-cache show gh >/dev/null 2>&1; then
            apt_pkgs+=("gh")
        fi
        if [ "${#apt_pkgs[@]}" -gt 0 ]; then
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${apt_pkgs[@]}" || true
        fi
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm jdk-openjdk github-cli || true
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install java-21-openjdk-devel gh || true
    elif command -v brew >/dev/null 2>&1; then
        export HOMEBREW_NO_AUTO_UPDATE=1
        brew install openjdk@21 gh 2>/dev/null || true
    fi
else
    echo "  [✓] Java y GitHub CLI ya están disponibles."
fi

wait

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
