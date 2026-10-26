#!/usr/bin/env bash
# ==============================================================================
# optimize-system.sh - Optimizador de Rendimiento de Hardware, Red y Batería/AC
# ==============================================================================
# Compatible con: Ubuntu, Debian, Fedora, Arch Linux, openSUSE, Bazzite, SteamOS
# 1. Detecta tipo de chasis: Desktop vs Laptop / Handheld
# 2. Configura optimizaciones de memoria (vm.max_map_count, swappiness, cache)
# 3. Configura optimizaciones de red (TCP BBR, Fast Open, bufferbloat reduction)
# 4. Desactiva WiFi Power Saving para evitar picos de ping en juegos online
# 5. Si es Laptop: perfil de máximo rendimiento dinámico al conectar la corriente (AC)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "    Optimizador de Rendimiento de Hardware, Red y Energía "
echo "=========================================================="

# -----------------------------------------------------------------------------
# 1. Detección de Hardware: Desktop vs Laptop / Handheld
# -----------------------------------------------------------------------------
IS_LAPTOP=false
CHASSIS_TYPE="desktop"

if command -v hostnamectl >/dev/null 2>&1; then
    CHASSIS_VAL=$(hostnamectl chassis 2>/dev/null || true)
    if [ -n "$CHASSIS_VAL" ]; then
        CHASSIS_TYPE="$CHASSIS_VAL"
    fi
fi

if [ -f /sys/class/dmi/id/chassis_type ]; then
    DMI_TYPE=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || true)
    # 8: Portable, 9: Laptop, 10: Notebook, 11: Handheld, 14: Sub-Notebook, 31: Convertible, 32: Detachable
    case "$DMI_TYPE" in
        8|9|10|11|14|31|32) CHASSIS_TYPE="laptop" ;;
    esac
fi

# Comprobar presencia física de batería
if compgen -G "/sys/class/power_supply/BAT*" > /dev/null || \
   [ "$CHASSIS_TYPE" = "laptop" ] || \
   [ "$CHASSIS_TYPE" = "notebook" ] || \
   [ "$CHASSIS_TYPE" = "convertible" ] || \
   [ "$CHASSIS_TYPE" = "handheld" ]; then
    IS_LAPTOP=true
fi

echo "[1/4] Detección de Hardware:"
if [ "$IS_LAPTOP" = true ]; then
    echo "  [✓] Tipo de dispositivo detectado: PORTÁTIL / LAPTOP (${CHASSIS_TYPE})"
else
    echo "  [✓] Tipo de dispositivo detectado: PC DE ESCRITORIO (DESKTOP)"
fi

# -----------------------------------------------------------------------------
# 2. Optimizaciones de Memoria, Sistema y Gaming (Sysctl)
# -----------------------------------------------------------------------------
echo "[2/4] Configurando optimizaciones del kernel para memoria y gaming..."

SYSCTL_FILE="/etc/sysctl.d/99-performance-gaming.conf"

SUDO_CMD=""
if [ "$EUID" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO_CMD="sudo"
    else
        echo "[!] Se requieren permisos de administrador para aplicar ajustes de sysctl."
    fi
fi

if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
    $SUDO_CMD mkdir -p /etc/sysctl.d /etc/security/limits.d

    $SUDO_CMD tee "$SYSCTL_FILE" >/dev/null << 'EOF'
# ==============================================================================
# Optimizaciones de Gaming y Rendimiento del Sistema
# ==============================================================================

# 1. Memoria Virtual y Asignación de Juegos (Crítico para Proton/Wine/DirectX 12)
# Evita crasheos de memoria en juegos como Star Citizen, Hogwarts Legacy, Unreal Engine
vm.max_map_count = 2147483642

# Evita el uso prematuro de swap a disco si hay suficiente RAM disponible
vm.swappiness = 10

# Mantiene cachés de inodos y directorios en RAM para acelerar carga de archivos
vm.vfs_cache_pressure = 50

# Límites de archivos abiertos del sistema
fs.file-max = 2097152

# Aumenta límite de inotify para proyectos grandes y entornos de desarrollo (IDE / Webpack / Rust)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 8192

# Mitigación de split locks (evita caídas bruscas de FPS en juegos DirectX 12)
kernel.split_lock_mitigate = 0

# ==============================================================================
# 2. Optimizaciones de Red y Baja Latencia (TCP BBR & Buffers)
# ==============================================================================

# Control de congestión TCP BBR (Google) para menor latencia y evitar bufferbloat
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# TCP Fast Open (reduce latencia en conexiones recurrentes)
net.ipv4.tcp_fastopen = 3

# Tamaño aumentado de buffers TCP para descargas de alta velocidad (Steam, fibra óptica)
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Gestión de cola de paquetes de red
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_slow_start_after_idle = 0
EOF

    # Aplicar cambios inmediatamente
    $SUDO_CMD sysctl --system >/dev/null 2>&1 || $SUDO_CMD sysctl -p "$SYSCTL_FILE" >/dev/null 2>&1 || true
    echo "  [✓] Parámetros de sysctl aplicados (vm.max_map_count, swappiness, TCP BBR)."

    # Configurar límites de descriptores de archivos para juegos
    $SUDO_CMD tee /etc/security/limits.d/99-gaming-limits.conf >/dev/null << 'EOF'
# Aumento de límites de archivos para juegos y emuladores
* soft nofile 1048576
* hard nofile 1048576
EOF
    echo "  [✓] Límites de descriptores de archivos configurados (nofile 1048576)."
fi

# -----------------------------------------------------------------------------
# 3. Optimización de Red WiFi (Eliminar picos de lag por WiFi Power Save)
# -----------------------------------------------------------------------------
echo "[3/4] Optimizando latencia de red WiFi..."

NM_CONF_DIR="/etc/NetworkManager/conf.d"
if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
    if [ -d "$NM_CONF_DIR" ] || command -v nmcli >/dev/null 2>&1; then
        $SUDO_CMD mkdir -p "$NM_CONF_DIR"
        $SUDO_CMD tee "${NM_CONF_DIR}/99-disable-wifi-powersave.conf" >/dev/null << 'EOF'
[connection]
# wifi.powersave: 2 = disabled, 3 = enabled.
# Desactivado para eliminar picos de ping aleatorios y microdesconexiones en juegos online.
wifi.powersave = 2
EOF
        echo "  [✓] WiFi Power Saving desactivado en NetworkManager (anti-lag para gaming)."
    fi
fi

# -----------------------------------------------------------------------------
# 4. Optimizaciones Específicas para Laptop (Máximo rendimiento en corriente AC)
# -----------------------------------------------------------------------------
echo "[4/4] Configuración de energía y rendimiento..."

if [ "$IS_LAPTOP" = true ]; then
    echo "  -> Configurando perfil de Máximo Rendimiento dinámico para Laptop..."

    if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
        # Crear script despachador de energía
        $SUDO_CMD tee /usr/local/bin/laptop-power-profile >/dev/null << 'EOF_PROFILE'
#!/usr/bin/env bash
# ==============================================================================
# laptop-power-profile - Cambia automáticamente perfiles CPU/GPU según AC o Batería
# ==============================================================================
set -euo pipefail

ON_AC=false

# Comprobar estado de adaptador de corriente AC
for supply in /sys/class/power_supply/A*/online /sys/class/power_supply/ADP*/online; do
    if [ -f "$supply" ] && [ "$(cat "$supply" 2>/dev/null)" = "1" ]; then
        ON_AC=true
        break
    fi
done

if [ "$ON_AC" = true ]; then
    # Conectado a la corriente: MÁXIMO RENDIMIENTO
    # 1. CPU EPP (Energy Performance Preference) a 'performance'
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        if [ -w "$epp" ]; then
            echo "performance" > "$epp" 2>/dev/null || true
        fi
    done

    # 2. CPU Governor si está disponible
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -w "$gov" ]; then
            if grep -q "performance" /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null; then
                echo "performance" > "$gov" 2>/dev/null || true
            fi
        fi
    done

    # 3. Si power-profiles-daemon está presente, cambiar a performance
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set performance 2>/dev/null || true
    fi

    # 4. Desactivar autosuspensión agresiva de PCIe en AC
    for pcie in /sys/bus/pci/devices/*/power/control; do
        if [ -w "$pcie" ]; then
            echo "on" > "$pcie" 2>/dev/null || true
        fi
    done

    logger -t "laptop-power-profile" "Alimentación por corriente (AC) detectada: Perfil MÁXIMO RENDIMIENTO activado."
else
    # En batería: MODO EQUILIBRADO
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        if [ -w "$epp" ]; then
            echo "balance_performance" > "$epp" 2>/dev/null || true
        fi
    done

    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set balanced 2>/dev/null || true
    fi

    logger -t "laptop-power-profile" "Alimentación por batería detectada: Perfil EQUILIBRADO activado."
fi
EOF_PROFILE

        $SUDO_CMD chmod +x /usr/local/bin/laptop-power-profile

        # Crear regla Udev para disparar el script al conectar o desconectar el cargador
        $SUDO_CMD tee /etc/udev/rules.d/99-laptop-ac-performance.rules >/dev/null << 'EOF_UDEV'
SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/local/bin/laptop-power-profile"
SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/local/bin/laptop-power-profile"
EOF_UDEV

        # Crear servicio systemd para evaluar el estado al arrancar
        $SUDO_CMD tee /etc/systemd/system/laptop-power-profile.service >/dev/null << 'EOF_SERVICE'
[Unit]
Description=Aplicar Perfil de Rendimiento de Laptop segun fuente de alimentacion
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/laptop-power-profile
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF_SERVICE

        $SUDO_CMD systemctl daemon-reload 2>/dev/null || true
        $SUDO_CMD systemctl enable --now laptop-power-profile.service 2>/dev/null || true
        $SUDO_CMD /usr/local/bin/laptop-power-profile 2>/dev/null || true

        echo "  [✓] Regla udev y servicio creados: al enchufar el cargador se activará automáticamente MÁXIMO RENDIMIENTO."
    fi
else
    # En PC de escritorio: aplicar governor / EPP de rendimiento
    echo "  -> PC de Escritorio: Optimizando perfiles del procesador..."
    if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
        for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            if [ -w "$epp" ]; then
                $SUDO_CMD sh -c "echo 'balance_performance' > '$epp'" 2>/dev/null || true
            fi
        done
        echo "  [✓] CPU EPP configurado para respuesta rápida sin retrasos."
    fi
fi

echo ""
echo "=========================================================="
echo " [✓] ¡Optimizaciones del sistema y red completadas con éxito!"
echo "=========================================================="
