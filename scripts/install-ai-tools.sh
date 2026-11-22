#!/usr/bin/env bash
# ==============================================================================
# install-ai-tools.sh - Suite de Inteligencia Artificial (Ollama, Claude, Antigravity, OpenBot, Hex)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

BIN_DIR="${HOME}/.local/bin"
LIB_DIR="${HOME}/.local/lib"
mkdir -p "${BIN_DIR}" "${LIB_DIR}"

echo "=== Suite de Inteligencia Artificial ==="

# 1. Ollama (con timeout y extracción zstd segura)
if command -v ollama >/dev/null 2>&1 || [ -x "${BIN_DIR}/ollama" ]; then
    echo "  [✓] Ollama ya está instalado."
elif [ "${LINUX_SETUP_SKIP_OLLAMA:-0}" = "1" ]; then
    echo "  [i] Ollama omitido por LINUX_SETUP_SKIP_OLLAMA=1."
else
    echo "  [+] Instalando Ollama (${DEB_ARCH})..."
    OLLAMA_TAR=""
    if [ "${DEB_ARCH}" = "amd64" ]; then
        OLLAMA_TAR="ollama-linux-amd64.tar.zst"
    elif [ "${DEB_ARCH}" = "arm64" ]; then
        OLLAMA_TAR="ollama-linux-arm64.tar.zst"
    fi

    if [ -n "${OLLAMA_TAR}" ] && command -v zstd >/dev/null 2>&1; then
        TMP_OLLAMA="/tmp/${OLLAMA_TAR}.$$"
        if safe_download "https://ollama.com/download/${OLLAMA_TAR}" "${TMP_OLLAMA}" 600; then
            tar --zstd -xf "${TMP_OLLAMA}" -C "${HOME}/.local" 2>/dev/null || true
            rm -f "${TMP_OLLAMA}"
        fi
    fi

    if [ -x "${BIN_DIR}/ollama" ] || command -v ollama >/dev/null 2>&1; then
        echo "  [✓] Ollama instalado correctamente."
        if [ "${HAS_SYSTEMD}" = true ]; then
            SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
            mkdir -p "${SYSTEMD_USER_DIR}"
            cat << EOF > "${SYSTEMD_USER_DIR}/ollama.service"
[Unit]
Description=Ollama Service (Local AI Model Runner)
After=network-online.target

[Service]
ExecStart=$(command -v ollama || echo "${BIN_DIR}/ollama") serve
Restart=always
RestartSec=3
Environment="PATH=${PATH}"

[Install]
WantedBy=default.target
EOF
            systemctl --user daemon-reload 2>/dev/null || true
            systemctl --user enable --now ollama.service 2>/dev/null || true
        fi
    else
        echo "  [!] No se pudo instalar Ollama automáticamente."
    fi
fi

# 2. Claude Code CLI
if command -v claude >/dev/null 2>&1 || [ -x "${BIN_DIR}/claude" ]; then
    echo "  [✓] Claude Code CLI ya está instalado."
else
    echo "  [+] Instalando Claude Code CLI..."
    if command -v bun >/dev/null 2>&1; then
        timeout 120 bun add -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
        if [ -x "${HOME}/.bun/bin/claude" ]; then
            ln -sf "${HOME}/.bun/bin/claude" "${BIN_DIR}/claude"
        fi
    elif command -v npm >/dev/null 2>&1; then
        timeout 120 npm install -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
    fi
    if command -v claude >/dev/null 2>&1 || [ -x "${BIN_DIR}/claude" ]; then
        echo "  [✓] Claude Code CLI instalado."
    else
        echo "  [!] No se pudo instalar Claude Code CLI."
    fi
fi

# 3. Claude Desktop App GUI, Google Antigravity App GUI, OpenBot, GrokBot y Hex
for sub in install-claude-desktop.sh install-antigravity.sh install-openbot.sh install-grokbot.sh install-hex.sh; do
    if [ -f "${SCRIPT_DIR}/${sub}" ]; then
        bash "${SCRIPT_DIR}/${sub}" || true
    fi
done

# 4. Atajos de terminal: 'agent' y 'c'
cat << 'EOF' > "${BIN_DIR}/agent"
#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
if command -v claude >/dev/null 2>&1; then
    exec claude "$@"
elif command -v uvx >/dev/null 2>&1; then
    exec uvx --from aider-chat aider "$@"
elif command -v ollama >/dev/null 2>&1; then
    exec ollama run llama3 "$@"
else
    echo "[!] No se encontró ningún agente de IA instalado."
    exit 1
fi
EOF
chmod +x "${BIN_DIR}/agent"

cat << 'EOF' > "${BIN_DIR}/c"
#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
if command -v claude >/dev/null 2>&1; then
    exec claude "$@"
else
    exec "${HOME}/.local/bin/agent" "$@"
fi
EOF
chmod +x "${BIN_DIR}/c"

echo "  [✓] Atajos 'agent' y 'c' listos en ${BIN_DIR}."
