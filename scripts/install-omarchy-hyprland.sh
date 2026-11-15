#!/usr/bin/env bash
# ==============================================================================
# install-omarchy-hyprland.sh - Perfil ligero Hyprland + Quickshell (Estilo Omarchy)
# ==============================================================================
# Instala un entorno Wayland completo, ultra-ligero y sin KDE ni GNOME,
# utilizando Hyprland + Quickshell con el shell oficial de Omarchy Quattro.
# Compatible con: Arch Linux, Fedora, Ubuntu/Debian, openSUSE, Bazzite (rpm-ostree)
# ==============================================================================
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
OMARCHY_DIR="${HOME}/.local/share/omarchy"
HYPR_CONF_DIR="${HOME}/.config/hypr"
QUICKSHELL_CONF_DIR="${HOME}/.config/quickshell"

mkdir -p "${BIN_DIR}" "${HYPR_CONF_DIR}" "${QUICKSHELL_CONF_DIR}"

echo "=========================================================="
echo "  Instalación de Perfil Ligero: Hyprland + Quickshell     "
echo "              (Arquitectura Omarchy Quattro)              "
echo "=========================================================="

# 1. Instalar Hyprland, Quickshell y utilidades Wayland ligeras
echo "[1/4] Instalando Hyprland, Quickshell y utilidades Wayland..."

if command -v rpm-ostree >/dev/null 2>&1; then
    echo "  [i] Sistema inmutable (Bazzite / OSTree) detectado."
    if ! command -v hyprland >/dev/null 2>&1; then
        echo "  [!] Nota sobre Hyprland en Bazzite / OSTree:"
        echo "      Fedora no empaqueta 'hyprland' en los repositorios oficiales base de rpm-ostree."
        echo "      En el ecosistema Bazzite/uBlue, para usar Hyprland como sesión principal se recomienda"
        echo "      rebasar a una imagen con Hyprland integrado (o usar Niri: sudo rpm-ostree install niri)."
        echo "  -> Se configurarán los archivos de Omarchy Quattro, Quickshell, plugins y atajos de Hyprland en tu usuario."
    else
        echo "  [✓] Hyprland ya está presente en el sistema."
    fi
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm \
        hyprland xdg-desktop-portal-hyprland hyprlock hypridle \
        wl-clipboard cliphist grim slurp brightnessctl playerctl \
        pamixer pavucontrol network-manager-applet fuzzel alacritty \
        ttf-jetbrains-mono-nerd qt6-wayland qt5-wayland xorg-xwayland \
        polkit-kde-agent sddm qt6-svg || true

    # Si no hay Display Manager activo (instalación mínima sin DE en CachyOS/Arch), habilitar SDDM
    if ! systemctl is-enabled sddm >/dev/null 2>&1 && \
       ! systemctl is-enabled gdm >/dev/null 2>&1 && \
       ! systemctl is-enabled lightdm >/dev/null 2>&1 && \
       ! systemctl is-enabled greetd >/dev/null 2>&1; then
        sudo systemctl enable sddm 2>/dev/null || true
        echo "  [✓] Gestor de login gráfico (SDDM) habilitado automáticamente."
    fi

    # Instalar quickshell desde repositorios oficiales o AUR (yay/paru)
    if ! command -v quickshell >/dev/null 2>&1; then
        if pacman -Si quickshell >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm quickshell || true
        elif command -v yay >/dev/null 2>&1; then
            yay -S --noconfirm quickshell-git || true
        elif command -v paru >/dev/null 2>&1; then
            paru -S --noconfirm quickshell-git || true
        fi
    fi
elif command -v dnf >/dev/null 2>&1; then
    # Habilitar COPRs comunitarios oficiales para Hyprland y Quickshell en Fedora
    sudo dnf copr enable -y solopasha/hyprland 2>/dev/null || true
    sudo dnf copr enable -y errornointernet/quickshell 2>/dev/null || true
    sudo dnf install -y --skip-unavailable \
        hyprland xdg-desktop-portal-hyprland hyprlock hypridle \
        quickshell wl-clipboard cliphist grim slurp brightnessctl \
        playerctl pamixer pavucontrol network-manager-applet fuzzel \
        alacritty jetbrains-mono-fonts qt6-qtwayland || true
elif command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -qq || true
    sudo apt-get install -y -qq \
        hyprland xdg-desktop-portal-hyprland wl-clipboard cliphist \
        grim slurp brightnessctl playerctl pamixer pavucontrol \
        network-manager-gnome fuzzel alacritty fonts-jetbrains-mono || true
elif command -v zypper >/dev/null 2>&1; then
    sudo zypper --non-interactive install \
        hyprland xdg-desktop-portal-hyprland hyprlock hypridle \
        wl-clipboard cliphist grim slurp brightnessctl playerctl \
        pamixer pavucontrol NetworkManager-applet fuzzel alacritty || true
fi

# 2. Clonar Shell Oficial de Omarchy (omacom/omarchy - rama quattro)
echo "[2/4] Descargando Shell Quickshell de Omarchy (omacom/omarchy)..."
if [ -d "${OMARCHY_DIR}/.git" ]; then
    echo "  -> Actualizando repositorio local de Omarchy..."
    git -C "${OMARCHY_DIR}" pull --ff-only 2>/dev/null || true
else
    rm -rf "${OMARCHY_DIR}"
    git clone --depth 1 --branch quattro https://github.com/omacom/omarchy.git "${OMARCHY_DIR}" 2>/dev/null || true
fi

mkdir -p "${BIN_DIR}" "${HYPR_CONF_DIR}" "${QUICKSHELL_CONF_DIR}" "${HOME}/.config/omarchy/plugins"

if [ -d "${OMARCHY_DIR}/shell" ]; then
    ln -sfn "${OMARCHY_DIR}/shell" "${QUICKSHELL_CONF_DIR}/omarchy"
    echo "  [✓] Shell Quickshell de Omarchy enlazado en ${QUICKSHELL_CONF_DIR}/omarchy"
fi

if [ -x "${OMARCHY_DIR}/bin/omarchy" ]; then
    ln -sfn "${OMARCHY_DIR}/bin/omarchy" "${BIN_DIR}/omarchy"
    echo "  [✓] CLI 'omarchy' enlazado en ${BIN_DIR}/omarchy (para 'omarchy plugin list/add/enable')"
fi

# 3. Crear lanzador inteligente de Quickshell estilo Omarchy
echo "[3/4] Creando lanzador ~/.local/bin/omarchy-shell..."
cat << 'EOF_SHELL' > "${BIN_DIR}/omarchy-shell"
#!/usr/bin/env bash
export OMARCHY_PATH="${OMARCHY_PATH:-${HOME}/.local/share/omarchy}"
export PATH="${OMARCHY_PATH}/bin:${HOME}/.local/bin:${PATH}"
SHELL_QML="${OMARCHY_PATH}/shell/shell.qml"
if command -v quickshell >/dev/null 2>&1 && [ -f "${SHELL_QML}" ]; then
    exec quickshell -p "${SHELL_QML}" "$@"
elif command -v waybar >/dev/null 2>&1; then
    exec waybar "$@"
else
    echo "[!] Quickshell no encontrado en el sistema."
    exit 1
fi
EOF_SHELL
chmod +x "${BIN_DIR}/omarchy-shell"

# 4. Generar configuración ligera y rápida de Hyprland (sin sobrescribir si el usuario ya personalizó)
echo "[4/4] Configurando Hyprland en ${HYPR_CONF_DIR}/hyprland.conf..."
if [ -f "${HYPR_CONF_DIR}/hyprland.conf" ] && ! grep -q "OMARCHY_QUICKSHELL_PROFILE" "${HYPR_CONF_DIR}/hyprland.conf"; then
    cp -f "${HYPR_CONF_DIR}/hyprland.conf" "${HYPR_CONF_DIR}/hyprland.conf.bak.$(date +%Y%m%d%H%M%S)"
fi

cat << 'EOF_HYPR' > "${HYPR_CONF_DIR}/hyprland.conf"
# ==============================================================================
# OMARCHY_QUICKSHELL_PROFILE - Hyprland + Quickshell (Ultra-Ligero sin KDE/GNOME)
# ==============================================================================

monitor=,preferred,auto,1

$terminal = alacritty
$menu = fuzzel

# --- AUTOARRANQUE ---
exec-once = ~/.local/bin/omarchy-shell
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = hypridle
exec-once = nm-applet --indicator

# --- ENTORNO WAYLAND ---
env = OMARCHY_PATH,$HOME/.local/share/omarchy
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland
env = SDL_VIDEODRIVER,wayland
env = MOZ_ENABLE_WAYLAND,1
env = ELECTRON_OZONE_PLATFORM_HINT,auto

# --- ENTRADA Y TRACKPAD (Optimizado para ThinkPad / Laptops) ---
input {
    kb_layout = us,latam
    kb_options = grp:alt_shift_toggle
    follow_mouse = 1
    sensitivity = 0

    touchpad {
        natural_scroll = true
        tap-to-click = true
        disable_while_typing = true
    }
}

gestures {
    workspace_swipe = true
}

# --- ESTÉTICA LIMPIA Y RENDIMIENTO ---
general {
    gaps_in = 4
    gaps_out = 8
    border_size = 2
    col.active_border = rgba(7aa2f7ee) rgba(bb9af7ee) 45deg
    col.inactive_border = rgba(414868aa)
    layout = dwindle
    resize_on_border = true
}

decoration {
    rounding = 8
    active_opacity = 1.0
    inactive_opacity = 0.96

    blur {
        enabled = true
        size = 4
        passes = 2
        new_optimizations = true
    }

    shadow {
        enabled = false
    }
}

animations {
    enabled = true
    bezier = snappy, 0.15, 0.9, 0.1, 1.0
    animation = windows, 1, 3, snappy, popin 85%
    animation = windowsOut, 1, 3, default, popin 85%
    animation = border, 1, 4, default
    animation = fade, 1, 3, default
    animation = workspaces, 1, 3, snappy, slide
}

dwindle {
    pseudotile = true
    preserve_split = true
}

misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    vfr = true
}

# --- ATAJOS PRINCIPALES (ESTILO OMARCHY) ---
$mainMod = SUPER

bind = $mainMod, RETURN, exec, $terminal
bind = $mainMod, SPACE, exec, $menu
bind = $mainMod, Q, killactive,
bind = $mainMod, W, killactive,
bind = $mainMod, F, fullscreen, 0
bind = $mainMod, T, togglefloating,
bind = $mainMod CTRL, L, exec, hyprlock
bind = $mainMod, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy
bind = $mainMod, E, exec, nautilus || dolphin || thunar
bind = $mainMod, B, exec, brave-browser || flatpak run com.brave.Browser

# Capturas de pantalla rápidas al portapapeles
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy

# Foco y movimiento de ventanas (Estilo Vim / Omarchy)
bind = $mainMod, h, movefocus, l
bind = $mainMod, l, movefocus, r
bind = $mainMod, k, movefocus, u
bind = $mainMod, j, movefocus, d
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Workspaces 1-9
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9

# Controles de Audio y Brillo (ThinkPad / Laptops)
bindel = , XF86AudioRaiseVolume, exec, pamixer -i 5
bindel = , XF86AudioLowerVolume, exec, pamixer -d 5
bindl  = , XF86AudioMute, exec, pamixer -t
bindel = , XF86MonBrightnessUp, exec, brightnessctl s +5%
bindel = , XF86MonBrightnessDown, exec, brightnessctl s 5%-
bindl  = , XF86AudioPlay, exec, playerctl play-pause
bindl  = , XF86AudioNext, exec, playerctl next
bindl  = , XF86AudioPrev, exec, playerctl previous

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
EOF_HYPR

# 5. Instalar y habilitar plugins populares de Omarchy
SCRIPT_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_SELF_DIR}/install-omarchy-plugins.sh" ]; then
    bash "${SCRIPT_SELF_DIR}/install-omarchy-plugins.sh"
fi

echo ""
echo "=========================================================="
echo " [✓] ¡Perfil Hyprland + Quickshell (Omarchy) configurado!"
echo "=========================================================="
echo " Para iniciarlo:"
echo "   1. Cierra tu sesión actual."
echo "   2. En la pantalla de login (SDDM/GDM), elige 'Hyprland'."
echo "   3. Atajos principales:"
echo "      Super + Enter    -> Terminal (Alacritty)"
echo "      Super + Espacio  -> Lanzador de aplicaciones"
echo "      Super + Q / W    -> Cerrar ventana"
echo "      Super + V        -> Historial de portapapeles"
echo "      Super + Ctrl + L -> Bloquear pantalla"
echo "=========================================================="
