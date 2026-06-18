return {
  "rmagatti/auto-session",
  -- Lazy: auto_restore is disabled, so the plugin is only needed when one of its
  -- session commands/maps fires. Nothing to do at startup.
  cmd = { "SessionRestore", "SessionSave", "SessionDelete" },
  keys = { "<leader>wr", "<leader>ws" },
  config = function()
    local auto_session = require("auto-session")

    auto_session.setup({
      auto_restore_enabled = false,
      auto_session_suppress_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
    })

    local keymap = vim.keymap

    keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
    keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory
  end,
}
