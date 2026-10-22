# 🚀 Linux Cross-Distro Setup

Script modular y universal para replicar y reinstalar automáticamente todos tus programas, herramientas y configuraciones en **cualquier distribución de Linux** (Ubuntu, Debian, Fedora, Arch, openSUSE, Bazzite, SteamOS, Pop!_OS, Linux Mint, etc.).

---

## 📦 Software Incluido y Métodos de Instalación

### 1. Aplicaciones Nativas / Especiales
* **Brave Origin (Nativo Oficial):**
  Instalado mediante el script oficial de Brave con `FLAVOR=origin` (añade los repositorios oficiales de Brave Software).
* **Visual Studio Code (Nativo Oficial):**
  Configura el repositorio oficial de Microsoft (`code`) con soporte para APT, DNF, Pacman y Zypper.
* **Steam:**
  Instala la versión nativa de la distro (con soporte multilib/RPM Fusion) o Flatpak según convenga.
* **Tailscale:**
  VPN mesh con instalación nativa universal y servicio `tailscaled` activado en `systemd`.
* **Grok Bot (AppImage):**
  Integración automática del AppImage en `~/.local/share/grok-bot/appimage` y acceso directo `.desktop` con icono.
* **Suite Craft (ArtCraft Launcher, GridCraft, DeckCraft, WordCraft, PdfCraft):**
  Incluye el bundle de instalación de ArtCraft Launcher en `bundles/`, desde el cual se gestionan y actualizan todas las aplicaciones de la suite Craft.

### 2. Aplicaciones Gráficas Complementarias (Flathub / Flatpak)
Garantizan idénticas versiones y configuración en cualquier distribución:
* **Desarrollo:** Apache NetBeans IDE (`org.apache.netbeans`).
* **Navegadores:** Google Chrome (`com.google.Chrome`), Mozilla Firefox (`org.mozilla.firefox`).
* **Seguridad y Productividad:** 1Password, Okular (PDFs), KCalc, Firmware Updater.
* **Multimedia:** Spotify, VLC Media Player, Haruna, Gwenview.
* **Gestión de Sistema y Gaming:** Flatseal, Warehouse, Kontainer (Podman/Docker), Protontricks, ProtonPlus.

### 3. Herramientas CLI Esenciales
Detección automática de gestor nativo (`apt`, `dnf`, `pacman`, `zypper` o `brew`):
* `git`, `gh` (GitHub CLI), `curl`, `wget`, `jq`, `ripgrep`, `tree`, `rsync`.
* `htop`, `btop`, `fastfetch`, `tmux`, `zsh`, compresores (`zip`, `unzip`, `p7zip`).
* Compiladores y herramientas base (`gcc`, `make`, `build-essential` / `base-devel`).

---

## ⚡ Modos de Instalación

```bash
# Modo 1: Híbrido / Nativo (Recomendado para Ubuntu, Debian, Fedora, Arch...)
# Instala Brave Origin, VS Code nativo, Steam nativo, Grok Bot, Craft Suite, CLI y Flatpaks
./setup.sh --native

# Modo 2: 100% Flatpak (Ideal para Bazzite, SteamOS o sistemas inmutables)
./setup.sh --flatpak-only

# Instalaciones individuales o específicas:
./setup.sh --brave       # Solo Brave Origin
./setup.sh --vscode      # Solo VS Code
./setup.sh --steam       # Solo Steam
./setup.sh --grokbot     # Solo Grok Bot
./setup.sh --craft       # Solo Suite Craft
./setup.sh --tailscale   # Solo Tailscale
./setup.sh --cli         # Solo herramientas de terminal

# Simulación (sin tocar el sistema):
./setup.sh --dry-run
```

---

## 🔄 Cómo Mantener Tus Paquetes Actualizados

Cuando instales aplicaciones nuevas en el futuro:
```bash
./scripts/export-my-apps.sh
git add packages/
git commit -m "Actualizar lista de programas"
git push
```
