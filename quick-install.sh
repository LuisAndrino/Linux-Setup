#!/usr/bin/env bash
# ==============================================================================
# quick-install.sh - Lanzador de Instalación Rápida y Desatendida (Quick Install)
# ==============================================================================
# Ejecuta la instalación completa de software, desarrollo, IA, gaming y optimizaciones
# sin requerir interacción manual.
#
# Uso:
#   ./quick-install.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/setup.sh" --yes "$@"
