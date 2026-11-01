#!/usr/bin/env bash
# ==============================================================================
# install-homebrew.sh - Instalador automatizado de Homebrew en Linux
# ==============================================================================
# Ideal para distros inmutables (Bazzite, SteamOS, Silverblue) y sistemas estándar
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          Instalación / Verificación de Homebrew          "
echo "=========================================================="

BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"

if command -v brew >/dev/null 2>&1 || [ -x "${BREW_PATH}" ]; then
    echo "  [✓] Homebrew ya está instalado en el sistema."
    if [ -x "${BREW_PATH}" ] && ! command -v brew >/dev/null 2>&1; then
        eval "$(${BREW_PATH} shellenv)"
    fi
else
    echo "  -> Instalando Homebrew para Linux..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        echo "  [!] Falló la instalación interactiva de Homebrew. Continuando..."
        exit 0
    }
fi

if [ -x "${BREW_PATH}" ]; then
    eval "$(${BREW_PATH} shellenv)"

    # Asegurar configuración en perfiles de shell
    SHELLENV_CMD='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    for rc in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile"; do
        if [ -f "$rc" ] && ! grep -q "linuxbrew" "$rc"; then
            echo -e "\n# Homebrew on Linux\n${SHELLENV_CMD}" >> "$rc"
            echo "  [✓] Homebrew añadido a: $rc"
        fi
    done
    echo "  [✓] Homebrew listo ($(brew --version | head -n1))."
fi
