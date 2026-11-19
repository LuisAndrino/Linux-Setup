#!/usr/bin/env bash
# ==============================================================================
# install-gaming-mode.sh - Configura "Return to Gaming Mode" universal (SteamOS UI)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common.sh"

BIN_DIR="${HOME}/.local/bin"
APP_DIR="${HOME}/.local/share/applications"
DESKTOP_DIR="${HOME}/Desktop"

mkdir -p "${BIN_DIR}" "${APP_DIR}"

echo "=== Return to Gaming Mode (SteamOS Gamepad UI) ==="

SCRIPT_TARGET="${BIN_DIR}/return-to-gaming-mode"

cat << 'EOF' > "${SCRIPT_TARGET}"
#!/usr/bin/env bash
set -euo pipefail

export PATH="${PATH}:/usr/games:${HOME}/.local/bin"

if [ "${1:-}" = "--session" ] || [ "${1:-}" = "--steamos" ]; then
    if command -v steamosctl >/dev/null 2>&1; then
        exec steamosctl switch-to-game-mode
    elif [ -x /usr/bin/return-to-gamemode ]; then
        exec /usr/bin/return-to-gamemode
    fi
fi

if ! command -v gamescope >/dev/null 2>&1; then
    echo "[!] Error: Gamescope no está instalado."
    exit 1
fi

STEAM_RUNNER=""
if command -v steam >/dev/null 2>&1; then
    STEAM_RUNNER="steam"
elif [ -x /usr/games/steam ]; then
    STEAM_RUNNER="/usr/games/steam"
elif command -v flatpak >/dev/null 2>&1 && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    STEAM_RUNNER="flatpak run com.valvesoftware.Steam"
else
    echo "[!] Error: Steam no está instalado."
    exit 1
fi

if pgrep -u "${USER:-$(id -un)}" -x steam >/dev/null 2>&1; then
    ${STEAM_RUNNER} -shutdown 2>/dev/null || pkill -TERM -u "${USER:-$(id -un)}" -x steam 2>/dev/null || true
    for _ in {1..10}; do
        pgrep -u "${USER:-$(id -un)}" -x steam >/dev/null 2>&1 || break
        sleep 0.5
    done
fi

GAMESCOPE_HELP="$(gamescope --help 2>&1 || true)"
GAMESCOPE_ARGS=(-e -f)
if printf '%s' "$GAMESCOPE_HELP" | grep -q -- '--adaptive-sync'; then
    GAMESCOPE_ARGS+=(--adaptive-sync)
fi
if printf '%s' "$GAMESCOPE_HELP" | grep -q -- '--touch-gestures'; then
    GAMESCOPE_ARGS+=(--touch-gestures)
fi
if command -v mangoapp >/dev/null 2>&1; then
    GAMESCOPE_ARGS+=(--mangoapp)
fi

exec gamescope "${GAMESCOPE_ARGS[@]}" -- ${STEAM_RUNNER} -gamepadui -steamos
EOF

chmod +x "${SCRIPT_TARGET}"
ln -sf "${SCRIPT_TARGET}" "${BIN_DIR}/gaming-mode"

DESKTOP_ENTRY="${APP_DIR}/return-to-gaming-mode.desktop"
cat << EOF > "${DESKTOP_ENTRY}"
[Desktop Entry]
Name=Return to Gaming Mode
Name[es]=Volver a Gaming Mode
Comment=Abre la interfaz SteamOS (Gamepad UI) en Gamescope
Exec=${SCRIPT_TARGET}
Icon=steam
Terminal=false
Type=Application
Categories=Game;Utility;
StartupNotify=false
EOF
chmod +x "${DESKTOP_ENTRY}"

if [ -d "${DESKTOP_DIR}" ] && [ ! -f "${DESKTOP_DIR}/Return.desktop" ] && [ ! -x "/usr/bin/return-to-gamemode" ]; then
    cp -f "${DESKTOP_ENTRY}" "${DESKTOP_DIR}/return-to-gaming-mode.desktop"
    chmod +x "${DESKTOP_DIR}/return-to-gaming-mode.desktop"
    command -v gio >/dev/null 2>&1 && gio set "${DESKTOP_DIR}/return-to-gaming-mode.desktop" metadata::trusted true 2>/dev/null || true
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${APP_DIR}" 2>/dev/null || true
fi

# Registrar sesión Wayland nativa (para SDDM/GDM) si el sistema es editable
WAYLAND_SESSIONS_DIR="/usr/share/wayland-sessions"
if [ "${IS_IMMUTABLE}" = false ] && [ ! -f "${WAYLAND_SESSIONS_DIR}/gamescope-session-steam.desktop" ]; then
    if run_root mkdir -p "${WAYLAND_SESSIONS_DIR}" /usr/local/bin 2>/dev/null; then
        if run_root tee /usr/local/bin/gamescope-session-steam >/dev/null << 'EOF_SESSION'
#!/usr/bin/env bash
export PATH="${PATH}:/usr/games:${HOME}/.local/bin"
export XDG_CURRENT_DESKTOP="gamescope"
export XDG_SESSION_DESKTOP="gamescope"
export XDG_SESSION_TYPE=x11
export ENABLE_GAMESCOPE_WSI=1
export QT_QPA_PLATFORM=xcb
export SDL_VIDEODRIVER=wayland

dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP 2>/dev/null || true

GAMESCOPE_HELP="$(gamescope --help 2>&1 || true)"
GAMESCOPE_FLAGS=(-e)
if printf '%s' "$GAMESCOPE_HELP" | grep -q -- '--adaptive-sync'; then
    GAMESCOPE_FLAGS+=(--adaptive-sync)
fi
if printf '%s' "$GAMESCOPE_HELP" | grep -q -- '--touch-gestures'; then
    GAMESCOPE_FLAGS+=(--touch-gestures)
fi
if command -v mangoapp >/dev/null 2>&1; then
    GAMESCOPE_FLAGS+=(--mangoapp)
fi

STEAM_CMD="steam"
if command -v steam >/dev/null 2>&1; then
    STEAM_CMD="steam"
elif [ -x /usr/games/steam ]; then
    STEAM_CMD="/usr/games/steam"
elif command -v flatpak >/dev/null 2>&1 && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    STEAM_CMD="flatpak run com.valvesoftware.Steam"
fi

exec gamescope "${GAMESCOPE_FLAGS[@]}" -- ${STEAM_CMD} -gamepadui -steamos
EOF_SESSION
        then
            run_root chmod +x /usr/local/bin/gamescope-session-steam 2>/dev/null || true
            run_root tee "${WAYLAND_SESSIONS_DIR}/gamescope-session-steam.desktop" >/dev/null << 'EOF_ENTRY' || true
[Desktop Entry]
Encoding=UTF-8
Name=SteamOS Gaming Mode
Comment=Sesión nativa de SteamOS sobre Gamescope
Exec=/usr/local/bin/gamescope-session-steam
Type=Application
DesktopNames=gamescope
EOF_ENTRY
            run_root tee /usr/local/bin/steamos-session-select >/dev/null << 'EOF_SELECT' || true
#!/usr/bin/env bash
pkill -TERM -u "${USER:-$(id -un)}" -x gamescope 2>/dev/null || true
steam -shutdown 2>/dev/null || true
EOF_SELECT
            run_root chmod +x /usr/local/bin/steamos-session-select 2>/dev/null || true
            echo "  [✓] Sesión Wayland registrada en ${WAYLAND_SESSIONS_DIR}/gamescope-session-steam.desktop"
        fi
    fi
fi

echo "  [✓] Comando listo: ${SCRIPT_TARGET} (alias 'gaming-mode')"
