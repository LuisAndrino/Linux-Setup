# 🐧 Linux Setup Universal - Multi-Distro Software Suite

Este repositorio te permite tener **exactamente los mismos programas, configuraciones y herramientas de trabajo** en cualquier distribución Linux:
* **Debian / Ubuntu** (y derivados: Pop!_OS, Linux Mint, Zorin OS)
* **Fedora** (Workstation clásica con DNF y sistemas atómicos como **Bazzite / Silverblue / Kinoite**)
* **Arch Linux** (y derivados: Manjaro, EndeavourOS, Garuda)
* **openSUSE** (Tumbleweed y Leap con Zypper)
* **SteamOS** (Steam Deck)

---

## ⚡ Instalación Rápida en 1 Línea (Cualquier máquina nueva)

En cualquier equipo nuevo o recién formateado con cualquier distro (Debian, Ubuntu, Fedora, Arch, openSUSE o Bazzite), solo abre tu terminal y ejecuta:

```bash
curl -sSL https://is.gd/andrino_setup | bash
```

O para instalar **TODO automáticamente** de forma desatendida:
```bash
curl -sSL https://is.gd/andrino_setup | bash -s -- --yes
```

---

## ⚡ Comandos Rápidos (Si ya tienes el repositorio)

### 1. Instalación Completa y Desatendida (Quick Install)
* **Instalar TODO (Apps, Dev, IA, Gaming, Multimedia, CLI):**
  ```bash
  ./quick-install.sh
  # o alternativamente:
  ./setup.sh --all
  ```

* **Instalar TODO incluyendo el escritorio Hyprland + Quickshell (Omarchy):**
  ```bash
  ./setup.sh --full
  # o alias:
  ./setup.sh --all-hyprland
  ```

* **Instalador interactivo estilo `archinstall` (con checkboxes y detalle de paquetes):**
  ```bash
  ./setup.sh
  # o:
  ./setup.sh --tui
  ```

### 2. Suites Modulares por Especialidad
```bash
./setup.sh --hyprland      # Escritorio Ligero Hyprland + Quickshell (Omarchy Quattro) + Plugins
./setup.sh --dev           # Suite Dev (Neovim Lua, Lazygit, Mise, uv, Bun, Java, GitHub CLI)
./setup.sh --neovim        # Solo Neovim v0.10+ y su configuración Lua moderna
./setup.sh --ai            # Suite de IA (Ollama local, Claude Code CLI, Aider, Antigravity, Grok)
./setup.sh --gaming        # Suite Gaming (Steam, Lutris, Heroic, Prism, RetroArch, ProtonUp-Qt, Goverlay)
./setup.sh --multimedia    # Suite Multimedia (OBS Studio, VLC, MPV, HandBrake, Krita, Audacity, GIMP, Blender, Spotify)
./setup.sh --messaging     # Clientes de mensajería (WhatsApp ZapZap + Telegram Desktop)
./setup.sh --optimize      # Optimizador de Hardware (ThinkPad T14 Gen 2 / Laptop), Memoria, Red TCP BBR y Batería/AC
./setup.sh --flatpak-only  # Modo 100% Flatpak (Ideal para Bazzite / SteamOS / distros inmutables)
./setup.sh --dry-run       # Simulación sin realizar cambios
```

---

## 🛠️ 1. Suite de Desarrollo y Programación
* **Neovim Moderno (`nvim` v0.10+):**
  * Gestor de paquetes `lazy.nvim` con carga diferida ultra-rápida.
  * Resaltado de sintaxis con `nvim-treesitter`.
  * Buscador difuso `telescope.nvim` (`<Espacio> + ff` para archivos, `<Espacio> + fg` para búsqueda de texto).
  * Explorador de archivos lateral `neo-tree` (`<Espacio> + e`).
  * Indicadores visuales de Git `gitsigns.nvim`, tema `tokyonight` y barra de estado `lualine`.
* **Lazygit (`lazygit`):** Interfaz visual de terminal para Git de máxima velocidad.
* **Mise (`mise`):** Gestor políglota de runtimes (Node.js, Python, Java, Rust, Go).
* **Astral `uv` / `uvx`:** Gestor de paquetes y entornos virtuales de Python hasta 100x más rápido que pip.
* **Bun (`bun`):** Runtime y gestor de paquetes JavaScript / TypeScript de última generación.
* **Java OpenJDK 21 LTS:** Requerido para desarrollo empresarial y herramientas como Apache NetBeans.
* **GitHub CLI (`gh`):** Interacción fluida con repositorios y pull requests desde la terminal.
* **Homebrew en Linux (`brew`):** Gestor de paquetes aislado para fórmulas y casks en distros estándar e inmutables.
* **Android SDK Tools (`adb` & `fastboot`):** Depuración, conexión y gestión de dispositivos móviles.
* **Suite Craft:** Aplicaciones de productividad (`gridcraft`, `deckcraft`, `pdfcraft`, `wordcraft`) con lanzador central ArtCraft.

---

## 🤖 2. Suite de Inteligencia Artificial
* **Ollama (`ollama`):** Ejecución de LLMs en local sin necesidad de internet (Llama 3, DeepSeek, Mistral, Qwen) con servicio systemd.
* **Claude Code CLI (`claude`):** Asistente oficial por terminal de Anthropic para desarrollo asistido por agentes.
* **Aider (`aider`):** Programación por parejas impulsada por IA integrada directamente en tus repositorios Git.
* **Google Antigravity (`antigravity`):** Plataforma y SDK de IA avanzada de Google DeepMind.
* **OpenBot (`openbot`):** Entorno de escritorio local-first para persistent AI teammates (Nightly Labs).
* **Hex (`hex`):** Dictado por voz 100% privado y local para Linux (Anoma.ly) con transcripción Whisper en tiempo real, soporte de atajos y servidor MCP para agentes.
* **Grok Bot (`grokbot`):** Cliente de IA para escritorio y terminal.
* **Atajos de Terminal Rápidos:**
  * `agent`: Selector inteligente que ejecuta tu agente activo disponible (`agent openbot`, `agent claude`, `agent aider`, etc.).
  * `c`: Alias de una sola tecla para lanzar el asistente AI en tu carpeta de trabajo.

---

## 🎮 3. Gaming, Emuladores y Optimización
* **Modo "Return to Gaming Mode" Universal (`return-to-gaming-mode`):**
  * Lanzador universal que abre Steam con interfaz **SteamOS Gamepad UI** dentro de una ventana/pantalla completa optimizada con **Valve Gamescope**.
  * Funciona idéntico en cualquier distro (Debian, Ubuntu, Fedora, Arch, openSUSE o Bazzite Desktop).
  * Incluye acceso directo en el Escritorio (`~/Desktop/return-to-gaming-mode.desktop`) y en el menú de aplicaciones.
  * Al salir de Steam (Apagar -> Salir de Steam), Gamescope se cierra y regresas al escritorio sin cerrar tu sesión.
* **Steam & Valve Gamescope:** Micro-compositor con reescalado FSR/NIS, soporte HDR y limitador de latencia.
* **Lossless Scaling FG para Vulkan (`lsfg-vk`):** Generación de fotogramas (Frame Generation) en juegos Vulkan/DirectX en Linux con interfaz visual de configuración (`lsfg-vk-ui`).
* **GameMode & MangoHud:** Optimización de prioridades del kernel y HUD en pantalla de FPS, temperaturas y consumo.
* **Launchers:** Lutris, Heroic Games Launcher (Epic/GOG/Amazon), Prism Launcher (Minecraft con mods), RecompLauncher (PC Ports nativos de N64 / Zelda 64).
* **Streaming en Steam Game Mode:** `StreamingServiceLauncher` para accesos a Netflix, YouTube, Disney+ y plataformas web.
* **Herramientas de Compatibilidad:** ProtonUp-Qt (instalación con 1 clic de GE-Proton / Wine-GE), Goverlay, Bottles, Protontricks.
* **Emulación y Consolas:** RetroArch (suite universal de emulación) y Chiaki4deck (PlayStation Remote Play).
* **Sincronización:** Ludusavi (respaldo automático de partidas guardadas de cualquier juego).

---

## 🎬 4. Multimedia, Creación y Edición
* **Video:** VLC, MPV (reproductor ultraligero de alta fidelidad), Haruna, HandBrake (transcodificación por hardware).
* **Streaming y Edición:** OBS Studio (grabación y directos), Kdenlive (editor de video no lineal).
* **Diseño y 3D:** Krita (pintura digital e ilustración), GIMP (retoque fotográfico), Blender (modelado y renderizado 3D).
* **Audio y Música:** Audacity (edición multipista), Strawberry Music Player (reproductor audiófilo FLAC bit-perfect), Spotify, ncspot (Spotify CLI en Rust).

---

## 🍿 5. Streaming, Películas Gratis, Torrents y Descargas
* **Stremio (`stremio`):** Plataforma de streaming de películas y series sin costo. Con compatibilidad para add-ons comunitarios (Torrentio, CyberFlix, OpenSubtitles v3) para ver cualquier contenido al instante con subtítulos.
* **Kodi Media Center (`kodi`):** Centro multimedia universal para reproducir contenido local o mediante add-ons de streaming (Balandro, Alfa, The Crew).
* **qBittorrent (`qbittorrent`) + 19 Motores de Búsqueda Integrados:**
  * Incluye preinstaladas y activas las extensiones de búsqueda para DonTorrent, ThePirateBay, 1337x, TorrentGalaxy, EZTV, LimeTorrents, SolidTorrents, BitSearch, Nyaa, Jackett, Prowlarr, etc.
  * Pestaña "Buscar" activada de fábrica en la configuración (`~/.var/app/org.qbittorrent.qBittorrent/` y `~/.config/qBittorrent/`).
* **JDownloader 2 (`jdownloader`):** Gestor integral de descargas directas multihilo con captura de portapapeles y descompresión automática.
* **FreeTube (`freetube`):** Cliente privado de YouTube sin anuncios ni seguimiento de cuenta.
* **Jellyfin Media Player (`jellyfin`):** Reproductor para streaming de librerías multimedia personales.
* **VLC Media Player (`vlc`):** El reproductor por excelencia para cualquier formato o códec existente.

---

## ⚡ 6. Optimizaciones de Sistema, Red y Portátil / Laptop
* **Detección Automática de Chasis:** Detecta si tu equipo es un PC de sobremesa (*Desktop*) o un ordenador portátil (*Laptop / Handheld*).
* **Gestión Dinámica de Energía para Laptops:**
  * **Conectada a la Corriente (AC):** Activa automáticamente el perfil **MÁXIMO RENDIMIENTO** (`performance` en CPU/EPP, desactivación de PCIe ASPM agresivo y límites de potencia).
  * **En Batería (DC):** Regresa a modo equilibrado (`balanced` / `balance_performance`) para proteger la autonomía.
* **Optimizaciones de Memoria y Gaming (Sysctl):**
  * `vm.max_map_count = 2147483642`: Esencial para que Proton, Wine y juegos DirectX 12 modernos no crasheen por asignación de memoria.
  * `vm.swappiness = 10`: Evita que el sistema recurra prematuramente a la swap si hay memoria RAM libre.
  * `vm.vfs_cache_pressure = 50`: Mantiene índices y cachés de archivos en RAM para acelerar la carga de texturas y proyectos de desarrollo.
  * `kernel.split_lock_mitigate = 0`: Reduce drásticamente caídas de fotogramas y *stuttering* en juegos pesados.
* **Baja Latencia y Red Ultra-Rápida:**
  * Algoritmo de congestión **TCP BBR** + cola `fq` para reducir el *bufferbloat* y mantener el ping bajo y estable en partidas online.
  * `wifi.powersave = 2`: Desactiva el ahorro de energía agresivo en adaptadores WiFi para eliminar picos aleatorios de latencia y micro-cortes.
  * Aumento de buffers de red para descargas a máxima velocidad en conexiones de fibra y Gigabit.

---

## 🪟 7. Escritorio Ligero: Hyprland + Quickshell (Estilo Omarchy Quattro)
Para quienes buscan un entorno ultra-fluido, minimalista y sin KDE ni GNOME:
* **Compositor Wayland:** Hyprland configurado con VFR (Variable Frame Rate), gestos de trackpad (`workspace_swipe = true`), y atajos estilo Vim.
* **Shell Gráfico:** Quickshell con el shell oficial de Omarchy (`omacom/omarchy` rama `quattro`).
* **Plugins Populares Preinstalados:**
  * `omni`: Command Palette con integración de IA.
  * `quickapps-hud`: Lanzador rápido estilo HUD.
  * `cliamp`: Overlay *Now Playing* multimedia.
  * `omarchy-overview`: Vista de pájaro de escritorios / workspaces.
  * `dizziee.system-stats` & `dizziee.power-profiles`: Monitoreo y selector de energía en barra.
  * `ericvrp.bar-autohide`: Auto-ocultación de la barra superior.
* **Gestor de Plugins CLI:** Integración con `omarchy plugin list`, `omarchy plugin add`, etc.

---

## 🔄 Rollback en Bazzite OS (Opcional)
Si utilizas Bazzite OS y deseas limpiar paquetes layered y dejar tu sistema en su imagen base:
```bash
sudo ./scripts/rollback-bazzite.sh
sudo systemctl reboot
```
