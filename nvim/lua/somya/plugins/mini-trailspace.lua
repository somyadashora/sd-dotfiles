-- mini.trailspace — highlight trailing whitespace, plus trim it on save.
--
-- Trailing whitespace shows up highlighted as you move around — but NOT on the
-- cursor's own line while you're in insert mode, so it doesn't flash at you
-- mid-type. `only_in_normal_buffers` keeps it out of terminals/help/pickers.
-- The default hl links to Error (loud red); we tone it down to a muted
-- catppuccin maroon blended toward the editor bg, re-applied on ColorScheme so
-- it survives styler.nvim's scheme-reload cycle (same trick as YankFlash).
--
-- <leader>uh toggles the highlight (under the +UI/Theme group), enabled by
-- default. The toggle flips vim.g.minitrailspace_disable — mini reads it for the
-- highlight, while our save-trim keys off the per-buffer b:minitrailspace_disable
-- flag, so toggling the highlight never changes the trimming behaviour.
--
-- We use mini for the HIGHLIGHT only and do the on-save TRIM ourselves: mini's
-- own MiniTrailspace.trim() ignores the disable flag (so it'd strip markdown too)
-- and restores the cursor with nvim_win_set_cursor, which can error when the
-- cursor sat on a just-removed space. Our substitute uses winsaveview/restore
-- and `keepjumps keeppatterns`, and honors the same b:minitrailspace_disable flag.
--
-- Skipped where trailing spaces are meaningful: markdown (two trailing spaces =
-- a hard line break) and diff. Setting `b:minitrailspace_disable` turns off BOTH
-- the highlight (mini reads it) and our trim below.
return {
  "echasnovski/mini.trailspace",
  version = "*",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local trailspace = require("mini.trailspace")
    trailspace.setup({
      only_in_normal_buffers = true,
    })

    local group = vim.api.nvim_create_augroup("SDTrailspace", { clear = true })

    -- Muted catppuccin highlight: maroon blended 60% toward the editor bg so
    -- trailing spaces are visible without shouting like the default Error red.
    local function set_hl()
      local ok, p = pcall(function() return require("catppuccin.palettes").get_palette() end)
      local accent = (ok and p and p.maroon) or "#eba0ac"
      local base = (ok and p and p.base) or "#1e1e2e"
      local function rgb(h)
        return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
      end
      local ar, ag, ab = rgb(accent)
      local br, bgc, bb = rgb(base)
      local t = 0.6 -- 60% toward base
      local function mix(a, b) return math.floor(a + (b - a) * t) end
      local bg = string.format("#%02x%02x%02x", mix(ar, br), mix(ag, bgc), mix(ab, bb))
      vim.api.nvim_set_hl(0, "MiniTrailspace", { bg = bg })
    end
    set_hl()
    -- Runs after mini's own ColorScheme handler (registered during setup above),
    -- so our tint wins instead of mini re-linking MiniTrailspace back to Error.
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_hl })

    -- Toggle the highlight (enabled by default; g.minitrailspace_disable is nil).
    vim.keymap.set("n", "<leader>uh", function()
      vim.g.minitrailspace_disable = not vim.g.minitrailspace_disable
      if vim.g.minitrailspace_disable then
        trailspace.unhighlight()
      else
        trailspace.highlight()
      end
      vim.notify(
        "Trailing-whitespace highlight " .. (vim.g.minitrailspace_disable and "off" or "on"),
        vim.log.levels.INFO
      )
    end, { desc = "Toggle trailing-whitespace highlight" })

    -- Disable highlight + trim where trailing whitespace carries meaning.
    local skip_ft = { "markdown", "diff" }
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = skip_ft,
      desc = "Leave trailing whitespace alone in markdown/diff",
      callback = function(args)
        vim.b[args.buf].minitrailspace_disable = true
      end,
    })

    -- Trim on save, unless the buffer opts out (markdown/diff) or isn't a real
    -- file (special buftype: terminals, help, pickers, ...).
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = group,
      pattern = "*",
      desc = "Strip trailing whitespace before writing the buffer",
      callback = function(args)
        if vim.b[args.buf].minitrailspace_disable or vim.bo[args.buf].buftype ~= "" then
          return
        end
        local view = vim.fn.winsaveview()
        vim.cmd([[keepjumps keeppatterns %s/\s\+$//e]])
        vim.fn.winrestview(view)
      end,
    })
  end,
}
