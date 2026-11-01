#!/usr/bin/env bash
# ==============================================================================
# install-hex.sh - Instalador de Hex (Local Voice Dictation)
# ==============================================================================
# Hex: Dictado por voz 100% privado y local para Linux (Anoma.ly)
# Sitio oficial: https://anoma.ly/hex/
# Repositorio: https://github.com/anomalyco/hex
# ==============================================================================
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"

echo "=========================================================="
echo "    Instalación de Hex (Local & Private Voice Dictation)  "
echo "=========================================================="

if command -v hex >/dev/null 2>&1 || [ -x "${BIN_DIR}/hex" ]; then
    echo "  [✓] Hex ya está instalado en el sistema ($(hex --version 2>/dev/null || echo 'en ~/.local/bin/hex'))."
else
    echo "  -> Instalando Hex para Linux (Anoma.ly)..."
    if curl -fsSL https://anoma.ly/hex/files/install-linux.sh | sh; then
        echo "  [✓] Hex instalado con éxito en ${BIN_DIR}/hex."
    else
        echo "  [!] Falló la instalación automática de Hex."
        echo "      Puedes intentar ejecutar directamente: curl -fsSL https://anoma.ly/hex/files/install-linux.sh | sh"
        exit 1
    fi
fi

# Verificar si se puede habilitar el servicio de usuario systemd para arranque opcional en segundo plano
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
fi

echo ""
echo "=========================================================="
echo " [✓] Hex configurado correctamente."
echo " Comandos útiles:"
echo "   hex app             -> Abrir la interfaz y configuración de Hex"
echo "   hex start           -> Iniciar el servicio en segundo plano"
echo "   hex model install   -> Descargar e instalar modelos de transcripción"
echo "   hex mcp             -> Servidor MCP de transcripción para agentes de IA"
echo "   hex quit            -> Cerrar el servicio de Hex"
echo "=========================================================="
