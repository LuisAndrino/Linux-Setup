# 🐧 Sistema de Replicación de Software Cross-Distro & Entorno Hyprland

Este repositorio te permite tener **exactamente los mismos programas, configuraciones y entorno de trabajo** en cualquier distribución basada en **Fedora** (Fedora Workstation clásica o sistemas atómicos como **Bazzite / Silverblue / Kinoite**).

---

## ⚡ Comandos Rápidos

### 1. Replicar todo tu software (Apps, Gaming, Flatpaks, CLI):
```bash
./setup.sh --yes
```

### 2. Instalar el entorno gráfico Hyprland:
```bash
./setup.sh --hyprland-desktop
```
*(Detecta automáticamente si estás en Fedora estándar con DNF o en Bazzite con rpm-ostree).*

---

## 🪟 Entorno de Escritorio Hyprland Ligero

Configuración moderna, ultra-ligera y minimalista inspirada en la ergonomía de Omarchy pero construida 100% nativa para el ecosistema Fedora/Bazzite:

### Componentes Principales:
* **Hyprland:** Tiling Wayland compositor con animaciones suaves, desenfoque (*blur* translúcido) y bordes dinámicos.
* **Waybar en cápsulas:** Barra superior flotante dividida en módulos tipo píldora/isla (workspaces, ventana activa, red, volumen, batería, reloj).
* **Rofi:** Menú modal centrado de búsqueda rápida.
* **Alacritty:** Terminal GPU de bajísima latencia con Starship prompt.
* **Gestor de Temas (`hypr-theme`):**
  * Compatible con las carpetas y paletas de **Omarchy** (`colors.toml` y fondos de pantalla).
  * Incluye temas preinstalados: Tokyo Night, Catppuccin, Nord, Gruvbox.
  * Cambia de tema al instante: `hypr-theme next` o `Super + T`.
  * Instala cualquier tema de GitHub: `hypr-theme install <git-url>`.
* **Gestor de Plugins y Extensiones (`hypr-plugin`):**
  * Permite añadir extensiones y widgets comunitarios: `hypr-plugin add <git-url>`.
* **Modo Agentes de IA Integrado:**
  * Atajo global `Super + C` para lanzar agentes (Google Antigravity, Claude Code, etc.).
  * Comando rápido `c "prompt"` desde cualquier terminal.
* **Compatibilidad X11/Java Garantizada:**
  * Parches para NetBeans y MySQL Workbench en Wayland.

---

## ⌨️ Atajos de Teclado Principales

| Atajo | Acción |
| :--- | :--- |
| `Super + Space` | **Buscador de aplicaciones (Rofi)** |
| `Super + Return` | Terminal rápida (Alacritty) |
| `Super + C` | **Lanzar Agente de IA** |
| `Super + T` | Cambiar tema en tiempo real |
| `Super + Q` | Cerrar ventana activa |
| `Super + F` | Pantalla completa |
| `Super + V` | Alternar ventana flotante |
| `Super + 1 .. 9` | Cambiar espacio de trabajo |
| `Super + SHIFT + 1 .. 9` | Mover ventana a espacio de trabajo |
| `Super + SHIFT + S` / `Print` | Captura de pantalla interactiva al portapapeles |

---

## 🔄 Restauración / Rollback en Bazzite

Si deseas revertir cualquier cambio en la capa del sistema de Bazzite y regresar al estado de fábrica de Gaming Mode:
```bash
sudo ./scripts/rollback-bazzite.sh
sudo systemctl reboot
```
