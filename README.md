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

*(El parámetro `--yes` o `--all` instala todo sin hacer preguntas: herramientas nativas, gaming, audio, comunicación, desarrollo y Flatpaks).*

---

## 🎮 Gaming, Rendimiento y Partidas
* **Launchers:**
  * **Steam:** Instalación nativa oficial de la distro o Flatpak según convenga.
  * **Lutris:** Gestor universal de juegos (GOG, Ubisoft, Epic, emuladores y scripts de la comunidad).
  * **Heroic Games Launcher:** Cliente nativo para Epic Games, GOG y Amazon Prime Games.
  * **Prism Launcher:** El lanzador de Minecraft por excelencia (instancias aisladas, mods Fabric/Forge/Quilt).
* **Partidas Guardadas y Mandos:**
  * **Ludusavi:** Respaldo y sincronización automática de partidas guardadas de Steam, Heroic, Lutris, Bottles y emuladores.
  * **AntiMicroX:** Mapeo de mandos/gamepads a teclado y ratón para juegos sin soporte nativo de mando.
* **Herramientas de Rendimiento:**
  * **Valve Gamescope (`gamescope`):** Micro-compositor de SteamOS para forzar resoluciones arbitrarias, escalado FSR/NIS, HDR y limitador de FPS.
  * **GameMode (`gamemode`):** Optimizador del kernel y CPU para máxima tasa de cuadros.
  * **MangoHud (`mangohud`):** Overlay en pantalla para FPS, temperaturas y consumo de hardware.
  * **ProtonUp-Qt:** Instala y actualiza GE-Proton, Wine-GE y Luxtorpeda con 1 clic.
  * **Goverlay:** Interfaz gráfica para calibrar MangoHud y filtros vkBasalt.
  * **Bottles, Protontricks y ProtonPlus:** Gestores de prefijos de Wine y dependencias DLL.

---

## 🎵 Audio, Voz y Música Hi-Res
* **Easy Effects:** El procesador de audio esencial para PipeWire. Aplica cancelación de ruido por IA (RNNoise) en tu micrófono para Discord/Slack y ecualizadores de alta definición para auriculares.
* **ncspot (Spotify en RUST):** Cliente ultra ligero escrito en Rust con interfaz ncurses y mínimo consumo de recursos.
* **Strawberry Music Player:** Reproductor audiófilo con salida bit-perfect directa (ALSA/PipeWire) para archivos FLAC y DSD.
* **Amberol:** Reproductor minimalista y moderno para reproducción local inmediata.

---

## 💻 Desarrollo, Runtimes y Terminal Rápida
* **Brave Origin (Nativo Oficial):** Repositorio oficial de Brave Software (`FLAVOR=origin`).
* **Visual Studio Code:** Repositorio oficial de Microsoft (`code`).
* **Java OpenJDK 21:** JDK esencial para Apache NetBeans y Prism Launcher.
* **Herramientas Dev en Terminal:**
  * **Lazygit:** La interfaz de terminal para Git más rápida y productiva.
  * **Mise (`mise-en-place`):** Gestor políglota de entornos (Node.js, Python, Java, Rust) sin ensuciar el sistema.
* **Google Antigravity:** Instalación oficial (AppImage / Homebrew Cask con accesos `.desktop`).
* **PowerShell (`pwsh`):** Microsoft PowerShell para Linux.
* **Terminal Rápida (Omarchy Style):** Alacritty (renderizado por GPU en Rust) y soporte Ghostty.

---

## 🔄 Sincronización, Mensajería y Red
* **LocalSend:** Transferencia directa de archivos estilo AirDrop entre PCs y móviles (Android/iOS) en tu red local o Tailscale.
* **Pika Backup:** Copias de seguridad incrementales cifradas de tus carpetas personales y configuraciones.
* **PeaZip:** Gestor avanzado de compresión para todos los formatos (ZIP, RAR, 7Z, TAR).
* **Tailscale:** Red VPN mesh con demonio `tailscaled` habilitado en systemd.
* **Grok Bot:** AppImage integrado en `~/.local/share/grok-bot/appimage`.
* **Suite Craft:** ArtCraft Launcher (bundle local) para GridCraft, DeckCraft, WordCraft y PdfCraft.
* **Waydroid (Emulador Android):**
  Ejecuta Android (LineageOS) dentro de un contenedor LXC con renderizado directo en Wayland y aceleración gráfica por GPU nativa. Permite correr aplicaciones y juegos APK de Android con integración directa en tu escritorio. Incluye herramientas de depuración y screen-mirroring (`scrcpy` y `adb`).
* **Mensajería:** WhatsApp (ZapZap), Telegram Desktop, Discord Oficial, Vesktop (Wayland audio), Slack.
* **Navegadores & Utilidades:** Google Chrome, Mozilla Firefox, 1Password, Obsidian, Flameshot, Okular, Kontainer.
* **Tienda y Ecosistema Flatpak (Trinidad Esencial):**
  * **Bazaar (`io.github.kolunmi.Bazaar`):** La mejor tienda gráfica dedicada exclusivamente a Flathub y Flatpaks (moderna, rápida, sin bloatware ni bloqueos).
  * **Warehouse (`io.github.flattool.Warehouse`):** Administrador avanzado para limpiar datos residuales, desinstalar y hacer downgrade de versiones Flatpak.
  * **Flatseal (`com.github.tchx84.Flatseal`):** Gestor visual de permisos de aplicaciones (acceso a carpetas, Wayland, X11, red, dispositivos).

---

## 🛠️ Comandos por Módulos (Opcionales)

```bash
./setup.sh              # Menú interactivo con selector de categorías
./setup.sh --gaming     # Instala solo la suite de Gaming (Lutris, Heroic, Prism, Ludusavi...)
./setup.sh --devtools   # Instala solo Java OpenJDK 21, Lazygit y Mise
./setup.sh --gamescope  # Instala y optimiza Gamescope
./setup.sh --dry-run    # Simula la instalación sin hacer cambios
```
