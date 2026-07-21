return {
  "rmagatti/auto-session",
  -- Fully lazy: auto_restore AND auto_save are both off, so nothing loads (or
  -- reopens a session) at startup — `nvim` opens clean on the dashboard — and
  -- nothing is saved on quit. Sessions are entirely manual: the plugin only
  -- loads when a session map/command fires (`<leader>ws` save / `<leader>wr`
  -- restore). No save-on-exit hook: quitting nvim never writes a session.
  cmd = "AutoSession",
  keys = { "<leader>wr", "<leader>ws" },
  config = function()
    local auto_session = require("auto-session")

    -- Note: `tabpages` is intentionally OMITTED. We rebuild the tab layout
    -- ourselves (core/session_tabs.lua) because mksession drops no-file tabs and
    -- can't carry our tab-local name/is_notes vars — so letting it also restore
    -- tabs just races our rebuild. mksession restores the current tab's windows +
    -- all buffers (`buffers`); reconcile() then builds every saved tab from the
    -- captured layout. `localoptions` (auto-session recommends it) brings back
    -- window-local filetype/highlighting; `winpos` keeps window geometry.
    vim.o.sessionoptions = "blank,buffers,curdir,folds,help,winsize,winpos,terminal,localoptions"

    auto_session.setup({
      auto_save = false,     -- never save on quit — sessions are manual (<leader>ws)
      auto_restore = false,  -- never auto-open a session at launch
      suppressed_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
      -- Keep empty/unnamed-buffer tabs: the default (true) closes every window
      -- whose buffer isn't a readable file before saving, so a blank tab's only
      -- window is closed and the tab is lost. We strip NvimTree windows ourselves
      -- via pre_save_cmds, so we don't need this — turn it off to preserve tabs.
      close_unsupported_windows = false,
      -- :mksession is unreliable for our project tabs — it drops tabs whose only
      -- window is empty / the alpha dashboard (so <leader>TP tabs with no file
      -- vanish) and can't persist the tab-local `name`/`is_notes_tab` vars at all.
      -- So persist the full ordered layout ourselves and reconcile it from the
      -- companion <session>x.vim after mksession runs (see core/session_tabs.lua).
      save_extra_cmds = {
        function()
          -- Park the layout STASHED in pre_save (before trees were closed) so
          -- post_restore can rebuild the tabs once nvim-tree is loaded. We only
          -- *store* it here (in x.vim, sourced mid-restore) — building it now,
          -- before the tree plugin is ready and while the restore is still
          -- settling, is exactly what made it race.
          local st = require("somya.core.session_tabs")
          return { "lua require('somya.core.session_tabs').set_pending(" .. st.stashed_serialized() .. ")" }
        end,
      },
      -- nvim-tree + session restore clash: nvim-tree's sync_root_with_cwd /
      -- update_focused_file autocmds (in the "NvimTree" augroup) re-init the
      -- explorer on every dir change, and the session source fires a storm of
      -- :tcd/DirChanged/BufEnter, thrashing the explorer -> E367 ("disabling auto
      -- save"). nvim-tree is often already loaded when you restore (tree open), so
      -- closing trees before save isn't enough — the live autocmds still fire.
      -- Fix in three parts:
      --   pre_save    — capture the layout, then close every tab's tree so the
      --                 session holds no NvimTree windows (close_trees keeps a
      --                 tree-only tab alive by emptying its window, not closing it).
      --   pre_restore — clear nvim-tree's autocmd group so NONE of its handlers
      --                 fire while the session is being sourced.
      --   post_restore— rebuild the tabs with those autocmds still silenced
      --                 (reconcile opens a tree in each tab), THEN re-register the
      --                 autocmds (autocmd.global()) so the trees track normally.
      pre_save_cmds = {
        function()
          -- Capture the full ordered layout FIRST (a tree-only tab is about to be
          -- emptied below), THEN strip trees so the session holds no NvimTree
          -- windows. close_trees keeps tree-only tabs alive by swapping them to an
          -- empty buffer instead of closing their last window.
          local st = require("somya.core.session_tabs")
          st.stash()
          st.close_trees()
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
            end)
            -- Silence nvim-tree's global autocmds BEFORE rebuilding the tabs:
            -- reconcile fires a storm of :tcd/:edit/:tabnew, and nvim-tree's
            -- DirChanged/BufEnter handlers (sync_root_with_cwd, update_focused_file)
            -- would re-init the explorer on each one, thrashing it and
            -- non-deterministically collapsing freshly-built tabs. Build with them
            -- off, then re-register so the tree tracks normally afterward.
            pcall(vim.api.nvim_clear_autocmds, { group = "NvimTree" })
            require("somya.core.session_tabs").reconcile_pending()
            pcall(function()
              require("nvim-tree.autocmd").global()
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
