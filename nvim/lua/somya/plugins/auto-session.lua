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

    -- `curdir` + `tabpages` already persist each tab's :tcd, so tabs scoped to
    -- different project dirs (<leader>TP) restore to their own root. Add
    -- `localoptions` (auto-session recommends it) so window-local filetype /
    -- highlighting come back correctly, and `winpos` for the full layout.
    vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

    auto_session.setup({
      auto_save = false,     -- exit-save is driven by our VimLeavePre hook (init)
      auto_restore = false,  -- never auto-open a session at launch
      suppressed_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
      -- Keep empty/unnamed-buffer tabs: the default (true) closes every window
      -- whose buffer isn't a readable file before saving, so a blank tab's only
      -- window is closed and the tab is lost. We strip NvimTree windows ourselves
      -- via pre_save_cmds, so we don't need this — turn it off to preserve tabs.
      close_unsupported_windows = false,
      -- :mksession does NOT persist tab-local vars, so the per-tab `name` (the
      -- bufferline tab label — "Notz", project basenames) and `is_notes_tab` flag
      -- are lost on restore. Re-emit them into the companion <session>x.vim, which
      -- the mksession footer sources after all tabs are recreated.
      save_extra_cmds = {
        function()
          local cmds = {}
          for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            local tabnr = vim.api.nvim_tabpage_get_number(tab)
            local ok_n, name = pcall(vim.api.nvim_tabpage_get_var, tab, "name")
            if ok_n and type(name) == "string" and name ~= "" then
              cmds[#cmds + 1] = ("call settabvar(%d, 'name', '%s')"):format(tabnr, (name:gsub("'", "''")))
            end
            local ok_z, is_notes = pcall(vim.api.nvim_tabpage_get_var, tab, "is_notes_tab")
            if ok_z and is_notes then
              cmds[#cmds + 1] = ("call settabvar(%d, 'is_notes_tab', v:true)"):format(tabnr)
            end
          end
          return cmds
        end,
      },
      -- nvim-tree + session restore clash: nvim-tree's sync_root_with_cwd /
      -- update_focused_file autocmds (in the "NvimTree" augroup) re-init the
      -- explorer on every dir change, and the session source fires a storm of
      -- :tcd/DirChanged/BufEnter, thrashing the explorer -> E367 ("disabling auto
      -- save"). nvim-tree is often already loaded when you restore (tree open), so
      -- closing trees before save isn't enough — the live autocmds still fire.
      -- Fix in three parts:
      --   pre_save    — close every tab's tree so the session holds no NvimTree
      --                 windows (clean session, nothing to recreate).
      --   pre_restore — clear nvim-tree's autocmd group so NONE of its handlers
      --                 fire while the session is being sourced.
      --   post_restore— re-register those autocmds (autocmd.global()) and reopen
      --                 the tree; tab.sync.open re-pins the rest on tab switches.
      pre_save_cmds = {
        function()
          if package.loaded["nvim-tree"] then
            pcall(vim.cmd, "tabdo NvimTreeClose")
          end
        end,
      },
      pre_restore_cmds = {
        function()
          if package.loaded["nvim-tree"] then
            pcall(vim.api.nvim_clear_autocmds, { group = "NvimTree" })
          end
        end,
      },
      post_restore_cmds = {
        function()
          vim.schedule(function()
            pcall(function()
              require("lazy").load({ plugins = { "nvim-tree.lua" } })
              require("nvim-tree.autocmd").global() -- re-register what pre_restore cleared
              require("nvim-tree.api").tree.open()
            end)
          end)
        end,
      },
    })

    local keymap = vim.keymap

    keymap.set("n", "<leader>wr", "<cmd>AutoSession restore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
    keymap.set("n", "<leader>ws", "<cmd>AutoSession save<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory
  end,
}
