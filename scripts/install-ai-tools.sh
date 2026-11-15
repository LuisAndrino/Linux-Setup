#!/usr/bin/env bash
# ==============================================================================
# install-ai-tools.sh - Instalador de Suite de Inteligencia Artificial
# ==============================================================================
# Incluye:
# 1. Ollama (Ejecución local de LLMs: Llama 3, DeepSeek, Mistral, Qwen)
# 2. Claude Code CLI (@anthropic-ai/claude-code)
# 3. Astral uv / uvx (Gestor moderno ultra-rápido de Python)
# 4. Aider (Asistente de programación AI en terminal)
# 5. Antigravity CLI (Google Antigravity)
# 6. Grok Bot CLI y AppImage
# 7. Atajos rápidos de terminal: 'c' y 'agent'
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
LIB_DIR="${HOME}/.local/lib"
mkdir -p "${BIN_DIR}" "${LIB_DIR}"

echo "=========================================================="
echo "    Instalación de Herramientas de Inteligencia Artificial"
echo "=========================================================="

# -----------------------------------------------------------------------------
# 1. Runtimes base (uv & Bun) en paralelo
# -----------------------------------------------------------------------------
echo "[1/3] Verificando runtimes base (uv & Bun)..."
(
    if ! command -v uv >/dev/null 2>&1 && [ ! -f "${BIN_DIR}/uv" ]; then
        curl -LsSf https://astral.sh/uv/install.sh | env CARGO_HOME="${HOME}/.local" sh 2>/dev/null || true
    fi
) &
(
    if ! command -v bun >/dev/null 2>&1 && [ ! -f "${HOME}/.bun/bin/bun" ]; then
        curl -fsSL https://bun.sh/install | bash 2>/dev/null || true
    fi
) &
wait

export PATH="${BIN_DIR}:${HOME}/.bun/bin:${PATH}"

# -----------------------------------------------------------------------------
# 2. Instalación en PARALELO de toda la Suite de IA
# -----------------------------------------------------------------------------
echo "[2/3] Instalando Suite de IA en paralelo (Ollama, Claude, Antigravity, OpenBot, GrokBot, Hex)..."

# Ollama (Background)
(
    if command -v ollama >/dev/null 2>&1 || [ -f "${BIN_DIR}/ollama" ]; then
        echo "  [✓] Ollama ya está instalado."
    else
        ARCH=$(uname -m)
        if [ "$EUID" -eq 0 ]; then
            curl -fsSL https://ollama.com/install.sh | sh >/dev/null 2>&1 || true
        else
            if [ "${ARCH}" = "x86_64" ]; then
                OLLAMA_TAR="ollama-linux-amd64.tar.zst"
            elif [ "${ARCH}" = "aarch64" ]; then
                OLLAMA_TAR="ollama-linux-arm64.tar.zst"
            else
                OLLAMA_TAR=""
            fi
            if [ -n "${OLLAMA_TAR}" ]; then
                curl -sSL "https://ollama.com/download/${OLLAMA_TAR}" | tar --zstd -xf - -C "${HOME}/.local" 2>/dev/null || true
                if [ -x "${BIN_DIR}/ollama" ]; then
                    echo "  [✓] Ollama instalado en ${BIN_DIR}/ollama."
                else
                    echo "  [!] No se pudo instalar Ollama (verifica conexión o 'zstd')."
                fi
            fi
        fi
    fi

    if command -v ollama >/dev/null 2>&1 || [ -f "${BIN_DIR}/ollama" ]; then
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
) &

# Claude Code CLI (Background)
(
    if command -v claude >/dev/null 2>&1 || [ -f "${BIN_DIR}/claude" ]; then
        echo "  [✓] Claude Code ya está instalado."
    else
        if command -v bun >/dev/null 2>&1; then
            bun add -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
            if [ -f "${HOME}/.bun/bin/claude" ]; then
                ln -sf "${HOME}/.bun/bin/claude" "${BIN_DIR}/claude"
            fi
        elif command -v npm >/dev/null 2>&1; then
            npm install -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
        fi
        echo "  [✓] Claude Code CLI listo."
    fi
) &

# Antigravity, Grok Bot, OpenBot y Hex (Background)
if [ -f "${SCRIPT_DIR}/install-antigravity.sh" ]; then
    bash "${SCRIPT_DIR}/install-antigravity.sh" &
fi

if [ -f "${SCRIPT_DIR}/install-grokbot.sh" ]; then
    bash "${SCRIPT_DIR}/install-grokbot.sh" &
fi

if [ -f "${SCRIPT_DIR}/install-openbot.sh" ]; then
    bash "${SCRIPT_DIR}/install-openbot.sh" &
fi

if [ -f "${SCRIPT_DIR}/install-hex.sh" ]; then
    bash "${SCRIPT_DIR}/install-hex.sh" &
fi

wait

# -----------------------------------------------------------------------------
# 3. Atajos Rápidos de Terminal: 'c' y 'agent'
# -----------------------------------------------------------------------------
echo "[3/3] Creando comandos y atajos de terminal ('c', 'agent')..."

# Comando 'agent'
cat << 'EOF' > "${BIN_DIR}/agent"
#!/usr/bin/env bash
# Selector inteligente de agentes de IA
if [ -n "${1:-}" ]; then
    TARGET="$1"
    shift
else
    TARGET=""
fi

case "${TARGET}" in
    claude)
        exec claude "$@"
        ;;
    aider)
        exec aider "$@"
        ;;
    grok)
        exec grokbot "$@"
        ;;
    openbot)
        exec openbot "$@"
        ;;
    ollama)
        exec ollama "$@"
        ;;
    antigravity|agy)
        exec antigravity "$@"
        ;;
    *)
        if command -v antigravity >/dev/null 2>&1; then
            exec antigravity "$@"
        elif command -v openbot >/dev/null 2>&1; then
            exec openbot "$@"
        elif command -v claude >/dev/null 2>&1; then
            exec claude "$@"
        elif command -v aider >/dev/null 2>&1; then
            exec aider "$@"
        elif command -v grokbot >/dev/null 2>&1; then
            exec grokbot "$@"
        else
            echo "No se encontró ningún agente AI instalado en el sistema."
            echo "Herramientas soportadas: antigravity, openbot, claude, aider, grokbot, ollama"
            exit 1
        fi
        ;;
esac
EOF

# Comando 'c' (Acceso rápido de una letra)
cat << 'EOF' > "${BIN_DIR}/c"
#!/usr/bin/env bash
exec agent "$@"
EOF

chmod +x "${BIN_DIR}/agent" "${BIN_DIR}/c"

echo ""
echo "=========================================================="
echo " [✓] ¡Herramientas de Inteligencia Artificial listas!"
echo "=========================================================="
echo " Comandos disponibles:"
echo "   ollama run llama3     -> Ejecutar modelos locales sin internet"
echo "   claude                -> Abrir Claude Code CLI"
echo "   aider                 -> Asistente de código Git en terminal"
echo "   antigravity           -> Google Antigravity Agent"
echo "   grokbot               -> Grok Bot"
echo "   openbot               -> OpenBot AI Teammates Workspace"
echo "   hex                   -> Hex (Local voice dictation con Whisper)"
echo "   agent / c             -> Lanzador rápido de tu agente de IA activo"
echo "=========================================================="
