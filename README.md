# 🚀 Linux Cross-Distro Setup

Script modular y universal para replicar y reinstalar automáticamente todos tus programas, herramientas y configuraciones en **cualquier distribución de Linux** (Ubuntu, Debian, Fedora, Arch, openSUSE, Bazzite, SteamOS, Pop!_OS, Linux Mint, etc.).

---

## 📦 ¿Qué incluye este instalador?

### 1. Aplicaciones Gráficas (GUI vía Flatpak/Flathub)
Garantizan **exactamente la misma versión y comportamiento** sin importar qué distribución uses:
* **Desarrollo y Programación:**
  * **Visual Studio Code** (`com.visualstudio.code`)
  * **Apache NetBeans IDE** (`org.apache.netbeans`)
* **Navegadores:**
  * Brave Browser (`com.brave.Browser`)
  * Google Chrome (`com.google.Chrome`)
  * Mozilla Firefox (`org.mozilla.firefox`)
* **Seguridad y Productividad:**
  * 1Password (`com.onepassword.OnePassword`)
  * Okular (Visor PDF / Documentos)
  * KCalc (Calculadora)
  * GNOME Firmware (Actualización de periféricos y hardware)
* **Multimedia y Entretenimiento:**
  * Spotify (`com.spotify.Client`)
  * VLC Media Player (`org.videolan.VLC`)
  * Haruna Video Player (`org.kde.haruna`)
  * Gwenview (Visor de imágenes)
* **Gestión de Flatpaks y Contenedores:**
  * Flatseal (Gestor visual de permisos de apps)
  * Warehouse (Gestión, actualización y limpieza de Flatpaks)
  * Kontainer (GUI para Docker / Podman)
  * Protontricks y ProtonPlus (Gestión de capas de compatibilidad Wine/Proton)

### 2. Red y Conectividad
* **Tailscale**: VPN mesh segura y acceso remoto entre tus equipos.
  * Instalado mediante el script oficial universal o soporte nativo.
  * Servicio `tailscaled` habilitado automáticamente en `systemd`.

### 3. Herramientas CLI Esenciales de Linux
Detección automática del gestor nativo (`apt`, `dnf`, `pacman`, `zypper` o `brew` en inmutables):
* **Control de versiones & Dev:** `git`, `gh` (GitHub CLI), `build-essential` / `base-devel` (`gcc`, `make`).
* **Utilidades del sistema:** `curl`, `wget`, `jq`, `ripgrep`, `tree`, `rsync`, `zip`, `unzip`, `p7zip`.
* **Monitoreo & Productividad:** `htop`, `btop`, `fastfetch`, `tmux`, `zsh`.

---

## ⚡ Instalación Rápida en una Nueva Máquina

### Opción A: Clonando este repositorio (Recomendado)
```bash
git clone <URL_DE_TU_REPOSITORIO> ~/linux-setup
cd ~/linux-setup
chmod +x setup.sh scripts/*.sh packages/*.sh
./setup.sh
```

### Opción B: Ejecución por partes o con parámetros
```bash
# Instalar todo de forma automática sin preguntas:
./setup.sh --all

# Instalar solo las aplicaciones gráficas (Flatpaks):
./setup.sh --flatpaks

# Instalar solo herramientas de terminal (CLI):
./setup.sh --cli

# Instalar y activar solo Tailscale:
./setup.sh --tailscale

# Probar qué haría sin hacer cambios:
./setup.sh --dry-run
```

---

## 🔄 Cómo Mantener Tu Lista de Programas Sincronizada

Cuando instales nuevas aplicaciones en tu máquina y quieras que se incluyan para el futuro:

1. Ejecuta el script de exportación:
   ```bash
   ./scripts/export-my-apps.sh
   ```
2. Este script leerá automáticamente tus Flatpaks instalados y actualizará `packages/flatpak-apps.txt`.
3. Sube los cambios a tu repositorio Git:
   ```bash
   git add packages/
   git commit -m "Actualizar lista de aplicaciones instaladas"
   git push
   ```

---

## 🛠️ Personalización Fácil
* Para **añadir** una nueva aplicación gráfica:
  Abre [Flathub](https://flathub.org), busca el programa, copia su ID (ej. `org.flameshot.Flameshot`) y pégalo en una línea de `packages/flatpak-apps.txt`.
* Para **quitar** un programa:
  Simplemente borra o comenta la línea con `#` en `packages/flatpak-apps.txt`.

---

## 🔐 Primeros Pasos Post-Instalación
1. **Tailscale:** Conéctate a tu red ejecutando:
   ```bash
   sudo tailscale up
   ```
2. **VS Code:** Inicia sesión con tu cuenta de GitHub o Microsoft para sincronizar automáticamente extensiones, temas y atajos (`Settings Sync`).
3. **1Password:** Inicia sesión para recuperar todas tus credenciales y llaves SSH.
