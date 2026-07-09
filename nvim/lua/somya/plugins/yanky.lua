-- Yank HISTORY / kill-ring: yanky.nvim keeps a persistent stack of everything
-- yanked (and deleted), so an overwritten unnamed register is never lost.
-- Chosen over yankbank-nvim for the ring-cycle-after-paste workflow and the
-- first-class Telescope picker (this config is Telescope-heavy — registers,
-- marks, jumplist, changelist all have pickers already).
--
-- Workflow:
--   • y / d / c fill the ring as usual (y goes through <Plug>(YankyYank), which
--     also keeps the cursor where it was instead of jumping to the region start).
--   • p / P / gp / gP put through yanky, which makes the put "ring-aware":
--     immediately after a put, [y / ]y swap the pasted text for the previous /
--     next ring entry in place — walk back to any older yank without a picker.
--     (yanky's default <c-p>/<c-n> cycle keys are avoided: <C-n> belongs to
--     vim-visual-multi.)
--   • <leader>y opens the ring in Telescope: <CR> puts the entry, <c-x> deletes
--     it from the ring. Custom mappings, NOT yanky's defaults — those bind
--     <c-k> to put-before, clobbering this config's <C-j>/<C-k> menu navigation.
--
-- The ring persists across sessions via shada storage (default; no sqlite
-- needed). The unnamed register already syncs with the system clipboard
-- (clipboard=unnamedplus in core/options.lua), and yanky's clipboard sync makes
-- external copies land in the ring too. Yank flash stays with the existing
-- TextYankPost autocmd (core/autocmds.lua) — yanky's on_yank highlight is off
-- to avoid a double flash; its on_put flash is kept (a put is not a yank, so
-- the autocmd doesn't cover it) with the same 200ms timing.
--
-- All maps are lazy.nvim `keys` triggers, so nothing loads until first use.
return {
  "gbprod/yanky.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  keys = {
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank (into yank ring)" },
    { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after (ring-aware)" },
    { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put before (ring-aware)" },
    { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put after, cursor after text" },
    { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put before, cursor after text" },
    { "[y", "<Plug>(YankyPreviousEntry)", desc = "Cycle to previous yank (after put)" },
    { "]y", "<Plug>(YankyNextEntry)", desc = "Cycle to next yank (after put)" },
    {
      "<leader>y",
      function()
        local telescope = require("telescope")
        telescope.load_extension("yank_history") -- idempotent; telescope is lazy, so load here
        telescope.extensions.yank_history.yank_history()
      end,
      desc = "Yank history (ring picker)",
    },
  },
  opts = function()
    local mapping = require("yanky.telescope.mapping")
    return {
      ring = {
        history_length = 100,
        storage = "shada", -- persists the ring across nvim sessions
      },
      system_clipboard = {
        sync_with_ring = true, -- external copies enter the ring
      },
      highlight = {
        on_put = true,
        on_yank = false, -- core/autocmds.lua already flashes yanks (YankFlash)
        timer = 200,
      },
      picker = {
        telescope = {
          use_default_mappings = false, -- defaults grab <c-k> (menu nav here)
          mappings = {
            default = mapping.put("p"), -- <CR> puts the selected entry
            i = {
              ["<c-x>"] = mapping.delete(), -- drop entry from the ring
            },
            n = {
              p = mapping.put("p"),
              P = mapping.put("P"),
              d = mapping.delete(),
            },
          },
        },
      },
    }
  end,
}
