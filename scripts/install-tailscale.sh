#!/usr/bin/env bash
# ==============================================================================
# install-tailscale.sh - Instalador y configurador universal de Tailscale
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          Instalación / Configuración de Tailscale         "
echo "=========================================================="

if command -v tailscale >/dev/null 2>&1; then
    echo "[✓] Tailscale ya está instalado en el sistema ($(tailscale version | head -n1))."
else
    echo "[+] Descargando e instalando Tailscale usando el script oficial universal..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL https://tailscale.com/install.sh | sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://tailscale.com/install.sh | sh
    else
        echo "[!] Error: curl o wget son requeridos para descargar Tailscale."
        exit 1
    fi
    echo "[✓] Tailscale instalado exitosamente."
fi

# Iniciar y habilitar el servicio del sistema (tailscaled)
if command -v systemctl >/dev/null 2>&1; then
    echo "[+] Verificando estado del servicio tailscaled..."
    if ! systemctl is-active --quiet tailscaled 2>/dev/null; then
        echo "[+] Habilitando e iniciando tailscaled en systemd..."
        sudo systemctl enable --now tailscaled
        echo "[✓] Servicio tailscaled iniciado."
    else
        echo "[✓] El servicio tailscaled ya está en ejecución."
    fi
fi

echo ""
echo "=========================================================="
echo " Tailscale está listo para conectarse."
echo " Para iniciar sesión y unirte a tu Tailnet ejecuta:"
echo "   sudo tailscale up"
echo "=========================================================="
