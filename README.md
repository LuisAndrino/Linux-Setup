# 🚀 Linux Cross-Distro Setup

Script modular y universal para replicar y reinstalar automáticamente todos tus programas, herramientas y configuraciones en **cualquier distribución de Linux** (Ubuntu, Debian, Fedora, Arch, openSUSE, Bazzite, SteamOS, Pop!_OS, Linux Mint, etc.).

---

## ⚡ El Comando Para Instalar TODO (Unattended / Automático)

Si ya tienes la carpeta o estás dentro de ella:
```bash
./setup.sh --yes
```

Si estás en una **máquina completamente nueva desde cero**, clona y ejecuta todo de un solo tirón:
```bash
git clone <URL_DE_TU_REPOSITORIO> ~/linux-setup && cd ~/linux-setup && ./setup.sh --yes
```

---

## 🎨 Entorno de Escritorio Estilo Omarchy (Cross-Distro)

Incluye una suite de configuración completa en `omarchy-desktop/` que replica la estética, fluidez y modo de agentes de Omarchy:

* **Compositor Hyprland:** Animaciones bezier elásticas, bordes redondeados con sombras suaves y compatibilidad reforzada para **Apache NetBeans** (`_JAVA_AWT_WM_NONREPARENTING=1`) y **MySQL Workbench** (`GDK_BACKEND=x11`).
* **Barra de Estado Waybar:** Diseño de píldoras/islas con indicadores de espacios de trabajo, ventana activa, CPU/RAM, audio, batería y estado del sistema.
* **Menú Rofi:** Lanzador de aplicaciones centrado con desenfoque de fondo y búsqueda difusa (*fuzzy*).
* **Terminal Rápida Alacritty:** Con paletas de colores idénticas a los temas de Omarchy.
* **Motor Dinámico de Temas (`omarchy-theme`):**
  Cambia la paleta de colores en tiempo real en Hyprland, Waybar, Alacritty y Rofi con un solo comando o atajo:
  * `Tokyo Night`
  * `Catppuccin Mocha`
  * `Nord`
  * `Gruvbox Material`
* **Modo de Agentes Autónomos:**
  * Atajo `Super + C` para lanzar tu agente de código favorito (**Google Antigravity**, **Claude Code**, **OpenCode**).
  * Comando rápido de terminal: `c "analiza este proyecto"` o simplemente `agent`.

### Atajos de Teclado Principales
* `Super + Space`: Lanzador de aplicaciones (Rofi)
* `Super + Return`: Terminal ultra-rápida (Alacritty)
* `Super + C`: **Modo Agente de IA**
* `Super + T`: Cambiar tema en tiempo real
* `Super + Q`: Cerrar ventana
* `Super + F`: Pantalla completa
* `Super + V`: Ventana flotante

### Cómo probar el entorno Omarchy en tu máquina actual:
```bash
cd ~/linux-setup
./setup.sh --omarchy-desktop
```
*(Puedes probar la terminal, el conmutador de temas con `omarchy-theme next` y el lanzador de agentes `c` inmediatamente, o iniciar Hyprland en sesión de escritorio completa).*

---

## 🎮 Gaming, Rendimiento y Emuladores
* **Lutris, Heroic Games Launcher, Prism Launcher y Steam.**
* **Ludusavi:** Respaldo y sincronización automática de partidas guardadas de PC.
* **AntiMicroX:** Mapeo de mandos a teclado/ratón.
* **Valve Gamescope (`gamescope`):** FSR/NIS, HDR, limitador de FPS y aislamiento de resolución.
* **ProtonUp-Qt, Goverlay, GameMode, MangoHud, Bottles, Protontricks y ProtonPlus.**
* **Waydroid:** Emulador de Android con aceleración gráfica por GPU nativa en Wayland.

---

## 🎵 Audio, Voz y Música Hi-Res
* **Easy Effects:** Supresión de ruido por IA (RNNoise) para micrófono en Discord/Slack y ecualizador FLAC.
* **ncspot:** Cliente de Spotify ligero en **Rust**.
* **Strawberry Music Player:** Reproductor audiófilo bit-perfect para archivos FLAC y DSD.
* **Amberol:** Reproductor minimalista de música local.

---

## 💻 Desarrollo, Base de Datos y CLI
* **Brave Origin (Nativo Oficial):** Repositorio oficial de Brave Software (`FLAVOR=origin`).
* **Visual Studio Code:** Repositorio oficial de Microsoft (`code`).
* **Java OpenJDK 21:** JDK para NetBeans y Prism Launcher.
* **MySQL Workbench & DBeaver Community:** Clientes SQL con compatibilidad asegurada.
* **Herramientas Dev:** Lazygit, Mise (gestor de runtimes políglota), PowerShell (`pwsh`), Google Antigravity.

---

## 🛍️ Tienda y Ecosistema Flatpak
* **Bazaar (`io.github.kolunmi.Bazaar`):** La mejor tienda gráfica dedicada a Flathub y Flatpaks.
* **Warehouse (`io.github.flattool.Warehouse`):** Limpiador de restos de apps y gestor de paquetes.
* **Flatseal (`com.github.tchx84.Flatseal`):** Gestor granular de permisos.

---

## 🔄 Sincronización y Archivos
* **LocalSend:** Transferencia de archivos estilo AirDrop entre PCs y móviles.
* **Pika Backup:** Copias de seguridad incrementales cifradas de carpetas y configs.
* **PeaZip:** Compresor multiformato avanzado.
* **Tailscale:** Red VPN mesh con demonio `tailscaled` habilitado en systemd.
