#!/usr/bin/env bash
# ==============================================================================
# install-neovim.sh - Instalador Universal y Moderno de Neovim (v0.10+) y Configuración Lua
# ==============================================================================
# Compatible con: Debian, Ubuntu, Fedora, Arch Linux, openSUSE, Bazzite, SteamOS
# ==============================================================================
set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
OPT_DIR="${HOME}/.local/opt"
CONFIG_DIR="${HOME}/.config/nvim"

mkdir -p "${BIN_DIR}" "${OPT_DIR}"

echo "=========================================================="
echo "    Instalación Universal de Neovim Moderno (v0.10+)"
echo "=========================================================="

NEED_INSTALL=true

if command -v nvim >/dev/null 2>&1; then
    CURRENT_VERSION=$(nvim --version | head -n1 | grep -Po 'v[0-9]+\.[0-9]+' || echo "v0.0")
    MAJOR_MINOR=$(echo "${CURRENT_VERSION}" | sed 's/v//')
    # Comprobar si es al menos 0.10
    if awk "BEGIN {exit !($MAJOR_MINOR >= 0.10)}"; then
        echo "[✓] Neovim ya está instalado y actualizado: $(nvim --version | head -n1)"
        NEED_INSTALL=false
    else
        echo "[!] Neovim existente (${CURRENT_VERSION}) es inferior a v0.10."
        echo "    Se instalará la versión oficial más reciente en ${BIN_DIR}/nvim."
    fi
fi

if [ "${NEED_INSTALL}" = true ]; then
    echo "[+] Instalando Neovim oficial más reciente..."
    ARCH=$(uname -m)
    if [ "${ARCH}" = "x86_64" ]; then
        NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    elif [ "${ARCH}" = "aarch64" ]; then
        NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
    else
        echo "[!] Arquitectura ${ARCH} no soportada para descarga directa. Intentando gestor nativo..."
        NVIM_URL=""
    fi

    INSTALLED_TARBALL=false
    if [ -n "${NVIM_URL}" ]; then
        echo "  -> Descargando Neovim desde GitHub releases..."
        TMP_DIR="/tmp/nvim-download"
        mkdir -p "${TMP_DIR}"
        if curl -sLo "${TMP_DIR}/nvim.tar.gz" "${NVIM_URL}"; then
            rm -rf "${OPT_DIR}/nvim-linux"
            mkdir -p "${OPT_DIR}/nvim-linux"
            tar -xzf "${TMP_DIR}/nvim.tar.gz" -C "${OPT_DIR}/nvim-linux" --strip-components=1
            ln -sf "${OPT_DIR}/nvim-linux/bin/nvim" "${BIN_DIR}/nvim"
            rm -rf "${TMP_DIR}"
            INSTALLED_TARBALL=true
            echo "  [✓] Neovim instalado en ${BIN_DIR}/nvim"
        fi
    fi

    if [ "${INSTALLED_TARBALL}" = false ]; then
        echo "  -> Fallback a gestores de paquetes nativos..."
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm neovim || true
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y neovim || true
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper --non-interactive install neovim || true
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -y && sudo apt-get install -y neovim || true
        fi
    fi
fi

# -----------------------------------------------------------------------------
# Configuración Lua de Neovim (Moderna, rápida y con Lazy.nvim)
# -----------------------------------------------------------------------------
echo ""
echo "[+] Configurando entorno Lua para Neovim..."

if [ -d "${CONFIG_DIR}" ] && [ ! -f "${CONFIG_DIR}/lua/config/lazy.lua" ]; then
    BACKUP_DIR="${CONFIG_DIR}.bak.$(date +%s)"
    echo "  [i] Respaldando configuración existente en ${BACKUP_DIR}"
    mv "${CONFIG_DIR}" "${BACKUP_DIR}"
fi

mkdir -p "${CONFIG_DIR}/lua/config" "${CONFIG_DIR}/lua/plugins"

# 1. init.lua
cat << 'EOF' > "${CONFIG_DIR}/init.lua"
-- Neovim Configuration (Universal Linux Setup)
require("config.options")
require("config.keymaps")
require("config.lazy")
EOF

# 2. lua/config/options.lua
cat << 'EOF' > "${CONFIG_DIR}/lua/config/options.lua"
local opt = vim.opt

-- Opciones generales
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.timeoutlen = 300
opt.updatetime = 200

-- Indentación
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Divisiones de ventana naturales
opt.splitbelow = true
opt.splitright = true
EOF

# 3. lua/config/keymaps.lua
cat << 'EOF' > "${CONFIG_DIR}/lua/config/keymaps.lua"
local keymap = vim.keymap.set
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Guardar y salir
keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Guardar archivo" })
keymap("n", "<leader>q", "<cmd>q<cr>", { desc = "Cerrar ventana" })
keymap("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Salir sin guardar" })

-- Navegación entre ventanas
keymap("n", "<C-h>", "<C-w>h", { desc = "Mover a ventana izquierda" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Mover a ventana inferior" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Mover a ventana superior" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Mover a ventana derecha" })

-- Manejo de buffers
keymap("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Buffer anterior" })
keymap("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Buffer siguiente" })
keymap("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Cerrar buffer" })

-- Limpiar resaltado de búsqueda
keymap("n", "<Esc>", "<cmd>nohlsearch<cr>")
EOF

# 4. lua/config/lazy.lua (Bootstrap automático de Lazy.nvim)
cat << 'EOF' > "${CONFIG_DIR}/lua/config/lazy.lua"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  defaults = { lazy = false },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
EOF

# 5. lua/plugins/ui.lua (Tema Tokyo Night, Lualine, Which-Key)
cat << 'EOF' > "${CONFIG_DIR}/lua/plugins/ui.lua"
return {
  -- Tema Tokyo Night
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "storm" },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd("colorscheme tokyonight")
    end,
  },

  -- Barra de estado inferior elegante
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "tokyonight",
        icons_enabled = true,
        component_separators = "|",
        section_separators = "",
      },
    },
  },

  -- Ayuda visual interactiva para atajos de teclado
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
EOF

# 6. lua/plugins/editor.lua (Telescope buscador, Neo-tree explorador, Gitsigns, Autopairs, Comment)
cat << 'EOF' > "${CONFIG_DIR}/lua/plugins/editor.lua"
return {
  -- Buscador difuso (Fuzzy Finder) de archivos y contenido
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Buscar archivos" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Buscar texto en proyecto" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buscar buffers abiertos" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Buscar ayuda" },
    },
  },

  -- Explorador de archivos en panel lateral
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorador de archivos" },
    },
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
        },
      },
    },
  },

  -- Indicadores de Git en el margen
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },

  -- Cierre automático de paréntesis, corchetes y comillas
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Comentarios rápidos con 'gcc'
  {
    "numToStr/Comment.nvim",
    opts = {},
  },
}
EOF

# 7. lua/plugins/treesitter.lua (Resaltado de sintaxis avanzado)
cat << 'EOF' > "${CONFIG_DIR}/lua/plugins/treesitter.lua"
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = { "bash", "c", "cpp", "lua", "python", "javascript", "typescript", "json", "yaml", "markdown" },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
EOF

echo "  [✓] Configuración de Neovim desplegada en ${CONFIG_DIR}."
echo ""
echo "=========================================================="
echo " [✓] ¡Neovim $(nvim --version 2>/dev/null | head -n1 || echo '') instalado y listo!"
echo "     Para abrirlo: escribe 'nvim'"
echo "     Atajos principales:"
echo "       <Espacio> + e   -> Abrir explorador de archivos"
echo "       <Espacio> + ff  -> Buscar archivos rápidamente"
echo "       <Espacio> + fg  -> Buscar texto en el proyecto"
echo "       <Espacio> + w   -> Guardar archivo actual"
echo "=========================================================="
