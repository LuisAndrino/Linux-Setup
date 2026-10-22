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

*(El parámetro `--yes` o `--all` instala todo sin hacer preguntas: herramientas nativas, gaming, comunicación, audio, terminal rápida y Flatpaks).*

---

## 🎮 Suite Completa de Gaming y Optimización
* **Launchers:**
  * **Steam:** Instalación nativa oficial de la distro o Flatpak según convenga.
  * **Lutris:** Gestor universal de juegos (GOG, Ubisoft, Epic, emuladores y scripts de la comunidad).
  * **Heroic Games Launcher:** Cliente nativo para Epic Games, GOG y Amazon Prime Games.
  * **Prism Launcher:** El lanzador de Minecraft por excelencia (instancias aisladas, mods Fabric/Forge/Quilt).
* **Herramientas de Rendimiento & Compatibilidad:**
  * **GameMode (`gamemode`):** Optimizador del kernel y CPU de Feral Interactive para máxima tasa de cuadros.
  * **MangoHud (`mangohud`):** Overlay en pantalla para FPS, temperaturas, reloj de GPU y consumo de RAM.
  * **ProtonUp-Qt:** Instala y actualiza GE-Proton, Wine-GE y Luxtorpeda con un solo clic.
  * **Goverlay:** Interfaz gráfica para calibrar MangoHud y filtros vkBasalt.
  * **Bottles:** Gestor visual de prefijos de Wine y dependencias de Windows.
  * **Protontricks y ProtonPlus:** Gestión de versiones y resolución de dependencias DLL.

---

## 🎵 Música y Audio de Alta Fidelidad
* **Spotify Ligero en RUST (`ncspot`):**
  Reemplaza el cliente pesado oficial de Spotify por **ncspot**, cliente ultra ligero escrito en Rust con bajo consumo de CPU y memoria.
* **Reproductor FLAC Audiófilo (Strawberry Music Player):**
  El reproductor de audio de alta resolución líder en Linux: reproducción bit-perfect, ecualizador avanzado, gestión de metadatos y soporte directo ALSA/PipeWire para archivos FLAC/DSD.
* **Amberol:**
  Reproductor minimalista y elegante para escuchar álbumes y archivos FLAC locales al instante.

---

## 📦 Lista de Software Integrado

### 1. Aplicaciones Nativas Oficiales
* **Brave Origin:** Script oficial con `FLAVOR=origin`.
* **VS Code:** Repositorio oficial de Microsoft (`code`).
* **Google Antigravity:** Instalación oficial (AppImage / Homebrew Cask con accesos `.desktop`).
* **PowerShell (`pwsh`):** Microsoft PowerShell para Linux.
* **Terminal Rápida (Omarchy Style):** Alacritty (renderizado por GPU en Rust) y soporte Ghostty.
* **Tailscale:** Red VPN mesh con demonio `tailscaled` habilitado en systemd.
* **Grok Bot:** AppImage integrado en `~/.local/share/grok-bot/appimage`.
* **Suite Craft:** ArtCraft Launcher (bundle local) para GridCraft, DeckCraft, WordCraft y PdfCraft.

### 2. Mensajería y Redes
* **WhatsApp:** ZapZap (`com.rtosta.zapzap`) con bandeja de sistema y notificaciones.
* **Telegram Desktop:** `org.telegram.desktop` oficial.
* **Discord Oficial:** `com.discordapp.Discord`.
* **Vesktop:** `dev.vencord.Vesktop` (Discord con screen audio en Wayland).
* **Slack:** `com.slack.Slack` oficial.

### 3. Productividad y Navegadores
* **Desarrollo:** Apache NetBeans IDE (`org.apache.netbeans`).
* **Navegadores:** Google Chrome, Mozilla Firefox.
* **Utilidades:** 1Password, Obsidian (notas Markdown), Flameshot (capturas), Okular (PDFs), KCalc, Flatseal, Warehouse, Kontainer.

---

## 🛠️ Comandos por Módulos (Opcionales)

```bash
./setup.sh              # Menú interactivo con selector de categorías
./setup.sh --gaming     # Instala solo la suite de Gaming (Lutris, Heroic, Prism, Steam...)
./setup.sh --brave      # Instala solo Brave Origin nativo
./setup.sh --antigravity # Instala solo Google Antigravity
./setup.sh --powershell # Instala solo PowerShell
./setup.sh --terminal   # Instala solo Alacritty
./setup.sh --dry-run    # Simula la instalación sin hacer cambios
```
