return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")


    local is_termux = vim.fn.executable("termux-info") == 1
    or (vim.env.PREFIX or ""):find("/com.termux/", 1, true) ~= nil
    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
    ensure_installed = is_termux and {
        "verible",
      } or {
        "verible",
        "lua_ls",
      },
      PATH = "prepend",
      -- automatically enable installed servers (required for vim.lsp.config() API)
      automatic_enable = {
        exclude = { "verible", "slang-server" }, -- exclude servers that require custom setup
      },
    })
  end,
}
