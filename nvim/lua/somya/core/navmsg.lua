-- Shared "you are here" message for list navigation.
--
-- gitsigns set the shape: after ]h it echoes "Hunk 1 of 5" to the cmdline
-- (gitsigns/actions/nav.lua), which answers the question every jump raises —
-- how far through the list am I, and is it worth pressing again? The same
-- treatment is applied to diagnostics and todo comments so all three speak in
-- one voice, each labelled by WHAT it landed on and coloured to match:
--
--   Warn 2 of 7      ]d   severity name, in the severity's colour
--   Change 1 of 5    ]h   hunk type,     in the GitSigns colour
--   TODO 3 of 4      ]t   keyword,       in the keyword's colour
--
-- The label doubles as "what am I looking at", so the sign column doesn't have
-- to be read to know whether the cursor stopped on an error or a hint.
local M = {}

-- gitsigns suppresses its own counter when 'shortmess' contains S; reusing that
-- flag means `:set shortmess+=S` silences every counter in this config at once.
function M.enabled()
  return vim.o.shortmess:find("S") == nil
end

-- Echo "<label> <index> of <total>" in highlight group `hl`.
--
-- Callers compute index/total themselves (each list has its own notion of
-- order), and pass nil index when the landing spot couldn't be located — the
-- message is a convenience, so a failure to place the cursor stays silent
-- rather than guessing a wrong number.
function M.echo(label, index, total, hl)
  if not M.enabled() then return end
  if not index or not total or total == 0 then return end
  -- A plugin's groups may not exist yet (or at all, on a stripped colorscheme);
  -- fall back to unhighlighted text rather than erroring mid-jump.
  if hl and vim.fn.hlexists(hl) == 0 then hl = nil end
  vim.api.nvim_echo(
    { { ("%s %d of %d"):format(label, index, total), hl or "None" } }, false, {})
end

return M
