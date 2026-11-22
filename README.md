# Linux-Setup (Instalador Universal Automático)

Instalador directo, sin menús ni opciones, compatible con **Ubuntu**, **Debian**, **Fedora**, **Arch Linux**, **openSUSE** y distros inmutables (**Bazzite / SteamOS**).

## Instalación en 1 línea

```bash
curl -fsSL https://raw.githubusercontent.com/LuisAndrino/Linux-Setup/main/bootstrap.sh | bash
```

O si ya clonaste el repositorio:

```bash
cd ~/linux-setup && ./setup.sh
```

## Qué instala automáticamente

1. **Pre-requisitos y CLI:** `curl`, `wget`, `git`, `gh`, `jq`, `ripgrep`, `fd`, `fzf`, `bat`, `zoxide`, `tmux`, `btop`, `htop`, `zsh`, `openssl`, `zstd`, `unzip`, `7zip`, `libfuse2` (para AppImages), `python3`, `Java JDK`, `flatpak`, `gamemode`, `mangohud`, `gamescope`, `vulkan-tools`, `adb`, `fastboot`.
2. **Apps nativas:** Brave Origin, Mozilla Firefox (APT oficial sin Snap en Ubuntu), Visual Studio Code, Steam, Gamescope, Tailscale, 1Password (+ CLI `op`), Alacritty.
3. **Gaming Mode universal:** comando `return-to-gaming-mode` (alias `gaming-mode`), acceso en el menú de aplicaciones y sesión Wayland `SteamOS Gaming Mode` (`/usr/share/wayland-sessions/gamescope-session-steam.desktop`).
4. **Suite de Desarrollo:** `uv`, `Bun`, `Mise`, `Lazygit`, `Neovim v0.10+` con configuración Lua.
5. **Suite de IA y Gaming de usuario:** `Ollama`, `Claude Code CLI`, `Google Antigravity`, `OpenBot`, `Grok Bot`, `Hex`, `lsfg-vk`, `Streaming Service Launcher`, motores de búsqueda para `qBittorrent` y atajos `agent` / `c`.
6. **Apps Flatpak (Flathub):** lista curada en `packages/flatpak-apps.txt` + `ArtCraft Launcher` (omitiendo automáticamente lo ya instalado de forma nativa).
7. **Optimizaciones de sistema y red:** `sysctl` gaming (`vm.max_map_count`, `swappiness=10`, TCP BBR), desactivación de WiFi Power Save y perfil AC automático para laptops.

## Garantías de estabilidad
- **Sin atascos en descargas:** todas las descargas usan `curl` con `--connect-timeout`, detección de atasco (`--speed-limit` / `--speed-time`), `--retry` y `--max-time`, más `timeout` en Flatpak y scripts externos.
- **Sin conflictos de locks:** las operaciones de `apt` (`DPkg::Lock::Timeout=120`), `dnf`, `pacman` y `zypper` corren en primer plano de forma secuencial y validan candidatos antes de instalar.
- **Totalmente no interactivo:** sin menús, sin preguntas bloqueantes y con pre-aceptación automática de EULAs (como Steam en Ubuntu/Debian).
