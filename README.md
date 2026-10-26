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

### 1. Instalación Completa y Desatendida (Recomendado)
Instala Desarrollo, Inteligencia Artificial, Gaming, Multimedia, Terminal y Flatpaks:
```bash
./setup.sh --yes
```

### 2. Suites Modulares por Especialidad
```bash
./setup.sh --dev          # Suite Dev (Neovim Lua, Lazygit, Mise, uv, Bun, Java, GitHub CLI)
./setup.sh --neovim       # Solo Neovim v0.10+ y su configuración Lua moderna
./setup.sh --ai           # Suite de IA (Ollama local, Claude Code CLI, Aider, Antigravity, Grok)
./setup.sh --gaming       # Suite Gaming (Steam, Lutris, Heroic, Prism, RetroArch, ProtonUp-Qt, Goverlay)
./setup.sh --multimedia   # Suite Multimedia (OBS Studio, VLC, MPV, HandBrake, Krita, Audacity, GIMP, Blender, Spotify)
./setup.sh --optimize     # Optimizador de Hardware (Laptop/Desktop), Memoria (sysctl), Red TCP BBR y Batería/AC
./setup.sh --flatpak-only # Modo 100% Flatpak (Ideal para Bazzite / SteamOS / distros inmutables)
./setup.sh --dry-run      # Simulación sin realizar cambios
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

---

## 🤖 2. Suite de Inteligencia Artificial
* **Ollama (`ollama`):** Ejecución de LLMs en local sin necesidad de internet (Llama 3, DeepSeek, Mistral, Qwen) con servicio systemd.
* **Claude Code CLI (`claude`):** Asistente oficial por terminal de Anthropic para desarrollo asistido por agentes.
* **Aider (`aider`):** Programación por parejas impulsada por IA integrada directamente en tus repositorios Git.
* **Google Antigravity (`antigravity`):** Plataforma y SDK de IA avanzada de Google DeepMind.
* **Grok Bot (`grokbot`):** Cliente de IA para escritorio y terminal.
* **Atajos de Terminal Rápidos:**
  * `agent`: Selector inteligente que ejecuta tu agente activo disponible.
  * `c`: Alias de una sola tecla para lanzar el asistente AI en tu carpeta de trabajo.

---

## 🎮 3. Gaming, Emuladores y Optimización
* **Modo "Return to Gaming Mode" Universal (`return-to-gaming-mode`):**
  * Lanzador universal que abre Steam con interfaz **SteamOS Gamepad UI** dentro de una ventana/pantalla completa optimizada con **Valve Gamescope**.
  * Funciona idéntico en cualquier distro (Debian, Ubuntu, Fedora, Arch, openSUSE o Bazzite Desktop).
  * Incluye acceso directo en el Escritorio (`~/Desktop/return-to-gaming-mode.desktop`) y en el menú de aplicaciones.
  * Al salir de Steam (Apagar -> Salir de Steam), Gamescope se cierra y regresas al escritorio sin cerrar tu sesión.
* **Steam & Valve Gamescope:** Micro-compositor con reescalado FSR/NIS, soporte HDR y limitador de latencia.
* **GameMode & MangoHud:** Optimización de prioridades del kernel y HUD en pantalla de FPS, temperaturas y consumo.
* **Launchers:** Lutris, Heroic Games Launcher (Epic/GOG/Amazon), Prism Launcher (Minecraft con mods).
* **Herramientas de Compatibilidad:** ProtonUp-Qt (instalación con 1 clic de GE-Proton / Wine-GE), Goverlay, Bottles, Protontricks.
* **Emulación y Consolas:** RetroArch (suite universal de emulación) y Chiaki4deck (PlayStation Remote Play).
* **Sincronización:** Ludusavi (respaldo automático de partidas guardadas de cualquier juego).

---

## 🎬 4. Multimedia, Creación y Streaming
* **Video:** VLC, MPV (reproductor ultraligero de alta fidelidad), Haruna, HandBrake (transcodificación por hardware).
* **Streaming y Edición:** OBS Studio (grabación y directos), Kdenlive (editor de video no lineal).
* **Diseño y 3D:** Krita (pintura digital e ilustración), GIMP (retoque fotográfico), Blender (modelado y renderizado 3D).
* **Audio y Música:** Audacity (edición multipista), Strawberry Music Player (reproductor audiófilo FLAC bit-perfect), Spotify, ncspot (Spotify CLI en Rust).

---

## ⚡ 5. Optimizaciones de Sistema, Red y Portátil / Laptop
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

## 🔄 Rollback en Bazzite OS (Opcional)
Si utilizas Bazzite OS y deseas limpiar paquetes layered y dejar tu sistema en su imagen base:
```bash
sudo ./scripts/rollback-bazzite.sh
sudo systemctl reboot
```
