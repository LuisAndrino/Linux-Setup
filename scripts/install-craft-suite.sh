#!/usr/bin/env bash
# ==============================================================================
# install-craft-suite.sh - Instalador de la suite Craft (ArtCraft, GridCraft, etc.)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_PATH="${SCRIPT_DIR}/bundles/artcraft-launcher-0.6.0-linux-x86_64.flatpak"

echo "=========================================================="
echo "      Instalación de Suite Craft (ArtCraft, GridCraft...) "
echo "=========================================================="

if ! command -v flatpak >/dev/null 2>&1; then
    echo "[!] Flatpak no está instalado. Asegúrate de instalar Flatpak primero."
    exit 1
fi

# 1. Instalar ArtCraft Launcher desde el bundle incluido
if flatpak info ai.storyteller.artcraft-launcher >/dev/null 2>&1; then
    echo "[✓] ArtCraft Launcher ya está instalado en este sistema."
else
    if [ -f "${BUNDLE_PATH}" ]; then
        echo "[+] Instalando ArtCraft Launcher desde el bundle local (${BUNDLE_PATH})..."
        flatpak install --user --bundle -y "${BUNDLE_PATH}"
        echo "[✓] ArtCraft Launcher instalado con éxito."
    else
        echo "[!] No se encontró el bundle de ArtCraft Launcher en: ${BUNDLE_PATH}"
        echo "    Descárgalo desde el sitio de ArtCraft y ejecuta:"
        echo "    flatpak install --user --bundle <archivo.flatpak>"
    fi
fi

# 2. Resumen y cómo iniciar las herramientas Craft
echo ""
echo "----------------------------------------------------------"
echo " Herramientas de la Suite Craft asociadas:"
echo "   - GridCraft (Hojas de cálculo y análisis)"
echo "   - DeckCraft (Presentaciones)"
echo "   - PdfCraft (Edición y lectura PDF)"
echo "   - WordCraft (Documentos)"
echo ""
echo " Con ArtCraft Launcher instalado, puedes abrirlo desde tu menú"
echo " de aplicaciones para actualizar o lanzar todas las herramientas."
echo " O ejecutarlas directamente por terminal si ya están descargadas:"
echo "   flatpak run ai.storyteller.gridcraft"
echo "   flatpak run ai.storyteller.deckcraft"
echo "   flatpak run ai.storyteller.pdfcraft"
echo "   flatpak run ai.storyteller.wordcraft"
echo "----------------------------------------------------------"
