#!/usr/bin/env bash
# ==============================================================================
# install-omarchy-plugins.sh - Instala los plugins más populares de Omarchy
# ==============================================================================
# Instala desde los repositorios verificados del Marketplace oficial de Omarchy:
#   - omni (Command Palette + IA, bjarneo/omarchy-shell-plugins)
#   - quickapps-hud (Lanzador rápido HUD, bjarneo/omarchy-shell-plugins)
#   - cliamp (Now Playing overlay, bjarneo/omarchy-shell-plugins)
#   - omarchy-overview (Vista general de workspaces Hyprland, AyushKr2003/omarchy-overview)
#   - dizziee.system-stats (Widget CPU/RAM/Temp en barra, JJDizz1L/dizziee.system-stats)
#   - dizziee.power-profiles (Widget perfiles de energía, JJDizz1L/dizziee.power-profiles)
#   - ericvrp.bar-autohide (Auto-ocultar barra en Hyprland, ericvrp/omarchy-bar-autohide)
# ==============================================================================
set -euo pipefail

OMARCHY_DIR="${HOME}/.local/share/omarchy"
PLUGINS_DIR="${HOME}/.config/omarchy/plugins"
SHELL_JSON="${HOME}/.config/omarchy/shell.json"
CACHE_DIR="${HOME}/.cache/omarchy-plugin-sources"

mkdir -p "${PLUGINS_DIR}" "${CACHE_DIR}" "${HOME}/.config/omarchy"

echo "=========================================================="
echo "  Instalando Plugins Populares de Omarchy (Quickshell)    "
echo "=========================================================="

install_git_plugin() {
    local plugin_id="$1"
    local repo_url="$2"
    local dest="${PLUGINS_DIR}/${plugin_id}"

    echo "  -> ${plugin_id} (${repo_url})..."
    if [ -d "${dest}/.git" ]; then
        git -C "${dest}" pull --ff-only 2>/dev/null || true
    else
        rm -rf "${dest}"
        git clone --depth 1 "${repo_url}" "${dest}" 2>/dev/null || {
            echo "  [!] No se pudo clonar ${plugin_id}"
            return 0
        }
    fi
}

# 1. Plugins individuales verificados en omacom/omarchy-plugin-marketplace
install_git_plugin "omarchy-overview" "https://github.com/AyushKr2003/omarchy-overview.git"
install_git_plugin "dizziee.system-stats" "https://github.com/JJDizz1L/dizziee.system-stats.git"
install_git_plugin "dizziee.power-profiles" "https://github.com/JJDizz1L/dizziee.power-profiles.git"
install_git_plugin "ericvrp.bar-autohide" "https://github.com/ericvrp/omarchy-bar-autohide.git"

# 2. Colección bjarneo/omarchy-shell-plugins (omni, quickapps-hud, cliamp)
BJARNEO_CACHE="${CACHE_DIR}/bjarneo-omarchy-shell-plugins"
echo "  -> Colección bjarneo/omarchy-shell-plugins (omni, quickapps-hud, cliamp)..."
if [ -d "${BJARNEO_CACHE}/.git" ]; then
    git -C "${BJARNEO_CACHE}" pull --ff-only 2>/dev/null || true
else
    rm -rf "${BJARNEO_CACHE}"
    git clone --depth 1 https://github.com/bjarneo/omarchy-shell-plugins.git "${BJARNEO_CACHE}" 2>/dev/null || true
fi

for sub_plugin in omni quickapps-hud cliamp; do
    if [ -f "${BJARNEO_CACHE}/${sub_plugin}/manifest.json" ]; then
        rm -rf "${PLUGINS_DIR}/${sub_plugin}"
        cp -a "${BJARNEO_CACHE}/${sub_plugin}" "${PLUGINS_DIR}/${sub_plugin}"
        echo "  [✓] Instalado ${sub_plugin}"
    fi
done

# 3. Registrar y habilitar plugins en ~/.config/omarchy/shell.json
if [ ! -f "${SHELL_JSON}" ] && [ -f "${OMARCHY_DIR}/config/omarchy/shell.json" ]; then
    cp "${OMARCHY_DIR}/config/omarchy/shell.json" "${SHELL_JSON}"
fi

if [ ! -f "${SHELL_JSON}" ]; then
    cat << 'EOF_JSON' > "${SHELL_JSON}"
{
  "version": 1,
  "bar": {
    "position": "top",
    "background": "opaque",
    "layout": {
      "left": [{ "id": "omarchy.menu" }, { "id": "omarchy.workspaces" }],
      "center": [{ "id": "omarchy.clock" }],
      "right": [{ "id": "omarchy.tray" }, { "id": "omarchy.network" }, { "id": "omarchy.audio" }, { "id": "omarchy.power" }]
    }
  },
  "plugins": []
}
EOF_JSON
fi

if command -v python3 >/dev/null 2>&1; then
    python3 - "${SHELL_JSON}" << 'EOF_PY'
import json, sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

# Habilitar overlays y servicios en plugins[]
desired_plugins = [
    "omni",
    "quickapps-hud",
    "cliamp",
    "omarchy-overview",
    "ericvrp.bar-autohide",
]

plugins = data.setdefault("plugins", [])
existing_ids = set()
for item in plugins:
    if isinstance(item, str):
        existing_ids.add(item)
    elif isinstance(item, dict) and "id" in item:
        existing_ids.add(item["id"])

for pid in desired_plugins:
    if pid not in existing_ids:
        plugins.append(pid)

# Añadir bar-widgets a bar.layout.right (antes de omarchy.power si existe)
bar = data.setdefault("bar", {})
layout = bar.setdefault("layout", {})
right = layout.setdefault("right", [])
right_ids = {item.get("id") for item in right if isinstance(item, dict)}

power_idx = next((i for i, item in enumerate(right) if isinstance(item, dict) and item.get("id") == "omarchy.power"), len(right))
for wid in ["dizziee.system-stats", "dizziee.power-profiles"]:
    if wid not in right_ids:
        right.insert(power_idx, {"id": wid})
        power_idx += 1

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
EOF_PY
    echo "  [✓] Plugins habilitados en ${SHELL_JSON}"
fi

# Rescan si omarchy CLI está disponible y el shell está activo
if command -v omarchy >/dev/null 2>&1; then
    omarchy plugin rescan 2>/dev/null || true
fi

echo "[✓] Plugins populares de Omarchy instalados en ${PLUGINS_DIR}."
