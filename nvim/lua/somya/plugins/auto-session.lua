return {
  "rmagatti/auto-session",
  -- Lazy on purpose: auto_restore is off, so nothing should load (or reopen a
  -- session) at startup — `nvim` opens clean on the dashboard. The plugin only
  -- loads when a session map/command fires, OR at exit via the init hook below.
  cmd = "AutoSession",
  keys = { "<leader>wr", "<leader>ws" },
  -- `init` runs at startup WITHOUT loading the plugin (it only registers an
  -- autocmd). This gives us save-on-exit without auto-session being pulled in on
  -- `nvim` invocation: the VimLeavePre callback force-loads the plugin only when
  -- you actually quit, then saves the session for the cwd (honoring
  -- suppressed_dirs). auto_save is left to our hook (see auto_save=false below),
  -- so it fires exactly once whether or not the plugin was loaded earlier.
  init = function()
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = vim.api.nvim_create_augroup("auto_session_save_on_exit", { clear = true }),
      callback = function()
        require("lazy").load({ plugins = { "auto-session" } })
        pcall(vim.cmd, "AutoSession save")
      end,
    })
  end,
  config = function()
    local auto_session = require("auto-session")

    auto_session.setup({
      auto_save = false,     -- exit-save is driven by our VimLeavePre hook (init)
      auto_restore = false,  -- never auto-open a session at launch
      suppressed_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
    })

    local keymap = vim.keymap

    keymap.set("n", "<leader>wr", "<cmd>AutoSession restore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
    keymap.set("n", "<leader>ws", "<cmd>AutoSession save<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory
  end,
}
