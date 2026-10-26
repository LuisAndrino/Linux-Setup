#!/usr/bin/env bash
# ==============================================================================
# install-gaming-mode.sh - Instalador del modo "Return to Gaming Mode" Universal
# ==============================================================================
# Crea un lanzador universal que abre Steam con interfaz Gamepad UI (SteamOS)
# dentro de una sesión de Gamescope optimizada, compatible con cualquier distro:
# Ubuntu, Debian, Fedora, Arch Linux, openSUSE y Bazzite Desktop.
# ==============================================================================
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"
DESKTOP_DIR="${HOME}/Desktop"

mkdir -p "${BIN_DIR}" "${APP_DIR}"

echo "=========================================================="
echo "   Configurando Modo Universal 'Return to Gaming Mode'    "
echo "=========================================================="

SCRIPT_TARGET="${BIN_DIR}/return-to-gaming-mode"

cat << 'EOF' > "${SCRIPT_TARGET}"
#!/usr/bin/env bash
# ==============================================================================
# return-to-gaming-mode - Abre SteamOS Gamepad UI en una ventana de Gamescope
# ==============================================================================
# Funciona igual en cualquier distribución Linux (Debian, Fedora, Arch, Ubuntu...)
# ==============================================================================
set -euo pipefail

# 1. Comprobar Gamescope
if ! command -v gamescope >/dev/null 2>&1; then
    echo "[!] Error: Gamescope no está instalado en el sistema."
    echo "    Puedes instalarlo ejecutando: ./setup.sh --gamescope"
    exit 1
fi

# 2. Localizar ejecutable de Steam (Nativo o Flatpak)
STEAM_RUNNER=""
if command -v steam >/dev/null 2>&1; then
    STEAM_RUNNER="steam"
elif flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    STEAM_RUNNER="flatpak run com.valvesoftware.Steam"
else
    echo "[!] Error: Steam no está instalado."
    echo "    Puedes instalarlo ejecutando: ./setup.sh --steam"
    exit 1
fi

# 3. Si Steam está abierto en el escritorio, cerrarlo para evitar conflictos de instancia
if pgrep -u "$USER" -x steam >/dev/null 2>&1; then
    echo "[*] Cerrando instancia de Steam en segundo plano..."
    steam -shutdown 2>/dev/null || pkill -TERM -u "$USER" -x steam 2>/dev/null || true
    for _ in {1..10}; do
        pgrep -u "$USER" -x steam >/dev/null 2>&1 || break
        sleep 0.5
    done
fi

# 4. Parámetros de Gamescope para recrear la experiencia SteamOS
GAMESCOPE_ARGS=(
    -e                       # Steam integration: enlaza controles, superposiciones y gestión de ciclo de vida
    -f                       # Modo pantalla completa
    --adaptive-sync          # VRR / FreeSync si la pantalla lo soporta
    --touch-gestures         # Gestos táctiles para menús de Steam
)

# Integrar MangoHud automáticamente si mangoapp está disponible en el sistema
if command -v mangoapp >/dev/null 2>&1; then
    GAMESCOPE_ARGS+=(--mangoapp)
fi

echo "[+] Lanzando SteamOS Gamepad UI en Gamescope..."
echo "  [Atajo] Super + F para alternar pantalla completa / ventana."
echo "  [Atajo] Para salir: Menú de Steam -> Encendido -> Salir de Steam (o Volver al Escritorio)."

exec gamescope "${GAMESCOPE_ARGS[@]}" -- ${STEAM_RUNNER} -gamepadui -steamos
EOF

chmod +x "${SCRIPT_TARGET}"
ln -sf "${SCRIPT_TARGET}" "${BIN_DIR}/gaming-mode"

# 5. Crear acceso directo .desktop en el menú de aplicaciones
DESKTOP_ENTRY="${APP_DIR}/return-to-gaming-mode.desktop"
cat << EOF > "${DESKTOP_ENTRY}"
[Desktop Entry]
Name=Return to Gaming Mode
Name[es]=Volver a Gaming Mode
Comment=Abre la interfaz de SteamOS (Gamepad UI) en un micro-compositor Gamescope optimizado
Exec=${SCRIPT_TARGET}
Icon=steam
Terminal=false
Type=Application
Categories=Game;Utility;
StartupNotify=false
EOF

chmod +x "${DESKTOP_ENTRY}"

# 6. Crear acceso directo en el Escritorio si la carpeta existe
if [ -d "${DESKTOP_DIR}" ]; then
    cp -f "${DESKTOP_ENTRY}" "${DESKTOP_DIR}/return-to-gaming-mode.desktop"
    chmod +x "${DESKTOP_DIR}/return-to-gaming-mode.desktop"
    if command -v gio >/dev/null 2>&1; then
        gio set "${DESKTOP_DIR}/return-to-gaming-mode.desktop" metadata::trusted true 2>/dev/null || true
    fi
    echo "  [✓] Acceso directo creado en el Escritorio: ~/Desktop/return-to-gaming-mode.desktop"
fi

echo "  [✓] Comando disponible en la terminal: 'return-to-gaming-mode' o 'gaming-mode'"
echo "  [✓] Entrada en el menú de aplicaciones: 'Return to Gaming Mode'"
echo "=========================================================="
echo " [✓] ¡Configuración de Return to Gaming Mode completada!"
echo "=========================================================="
