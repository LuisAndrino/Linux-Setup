#!/usr/bin/env bash
# ==============================================================================
# install-dev-tools.sh - Suite de Desarrollo (Neovim, Lazygit, Mise, uv, Bun)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"

echo "=== Herramientas de Desarrollo (Neovim, Lazygit, Mise, uv, Bun) ==="

# 1. Astral uv (Python)
if command -v uv >/dev/null 2>&1 || [ -x "${BIN_DIR}/uv" ]; then
    echo "  [✓] uv ya está instalado."
else
    echo "  [+] Instalando uv..."
    TMP_UV="/tmp/uv-install-$$.sh"
    if safe_download "https://astral.sh/uv/install.sh" "${TMP_UV}" 60; then
        timeout 120 env CARGO_HOME="${HOME}/.local" UV_INSTALL_DIR="${BIN_DIR}" sh "${TMP_UV}" >/dev/null 2>&1 || \
            echo "  [!] Falló el instalador de uv."
        rm -f "${TMP_UV}"
    fi
    if [ -x "${BIN_DIR}/uv" ] || command -v uv >/dev/null 2>&1; then
        echo "  [✓] uv instalado."
    fi
fi

# 2. Bun (JS/TS runtime)
if command -v bun >/dev/null 2>&1 || [ -x "${HOME}/.bun/bin/bun" ]; then
    echo "  [✓] Bun ya está instalado."
else
    echo "  [+] Instalando Bun..."
    TMP_BUN="/tmp/bun-install-$$.sh"
    if safe_download "https://bun.sh/install" "${TMP_BUN}" 60; then
        timeout 180 bash "${TMP_BUN}" >/dev/null 2>&1 || echo "  [!] Falló el instalador de Bun."
        rm -f "${TMP_BUN}"
    fi
    if [ -x "${HOME}/.bun/bin/bun" ]; then
        ln -sf "${HOME}/.bun/bin/bun" "${BIN_DIR}/bun"
        echo "  [✓] Bun instalado."
    fi
fi

# 3. Mise (gestor de runtimes)
if command -v mise >/dev/null 2>&1 || [ -x "${BIN_DIR}/mise" ]; then
    echo "  [✓] Mise ya está instalado."
else
    echo "  [+] Instalando Mise..."
    TMP_MISE="/tmp/mise-install-$$.sh"
    if safe_download "https://mise.run" "${TMP_MISE}" 60; then
        timeout 180 sh "${TMP_MISE}" >/dev/null 2>&1 || echo "  [!] Falló el instalador de Mise."
        rm -f "${TMP_MISE}"
    fi
    if [ -x "${BIN_DIR}/mise" ] || command -v mise >/dev/null 2>&1; then
        echo "  [✓] Mise instalado."
    fi
fi

# 4. Lazygit (x86_64 y arm64)
if command -v lazygit >/dev/null 2>&1 || [ -x "${BIN_DIR}/lazygit" ]; then
    echo "  [✓] Lazygit ya está instalado."
else
    echo "  [+] Instalando Lazygit..."
    LG_ARCH="${ARCH}"
    [ "${LG_ARCH}" = "aarch64" ] && LG_ARCH="arm64"
    LG_VER="$(safe_fetch "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 20 | grep -Po '"tag_name":\s*"v\K[^"]*' | head -n1 || true)"
    LG_VER="${LG_VER:-0.44.1}"
    TMP_LG="/tmp/lazygit-$$"
    mkdir -p "${TMP_LG}"
    if safe_download "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_${LG_ARCH}.tar.gz" "${TMP_LG}/lazygit.tar.gz" 120; then
        tar -xzf "${TMP_LG}/lazygit.tar.gz" -C "${TMP_LG}" lazygit 2>/dev/null || true
        if [ -f "${TMP_LG}/lazygit" ]; then
            install -m 755 "${TMP_LG}/lazygit" "${BIN_DIR}/lazygit"
            echo "  [✓] Lazygit v${LG_VER} instalado en ${BIN_DIR}/lazygit."
        fi
    else
        echo "  [!] No se pudo descargar Lazygit."
    fi
    rm -rf "${TMP_LG}"
fi

# 5. Neovim v0.10+ y configuración Lua
if [ -f "${SCRIPT_DIR}/install-neovim.sh" ]; then
    bash "${SCRIPT_DIR}/install-neovim.sh" || true
fi

# 6. Java 25 LTS (Eclipse Temurin OpenJDK 25)
if [ -f "${SCRIPT_DIR}/install-java25.sh" ]; then
    bash "${SCRIPT_DIR}/install-java25.sh" || true
fi

# 7. RunJS (JavaScript/TypeScript Desktop Playground)
if [ -f "${SCRIPT_DIR}/install-runjs.sh" ]; then
    bash "${SCRIPT_DIR}/install-runjs.sh" || true
fi

ensure_user_path_in_rc
