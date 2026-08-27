-- mini.indentscope — jump to start/end of current indent block
--
-- MOTIONS (normal & visual & operator-pending):
--   [i   jump to the top    boundary of the current indent scope
--   ]i   jump to the bottom boundary of the current indent scope
--
-- TEXT OBJECTS:
--   ii   inner indent scope  (excludes the surrounding blank/header lines)
--   ai   around indent scope (includes the surrounding blank/header lines)
--   Example: dii deletes the block, vii selects it, >ii indents it
--
-- SYMBOL:
--   The scope is drawn with a dotted ┊ line (same glyph as the indent-blankline
--   guides), in a soft desaturated lavender (MiniIndentscopeSymbol) so the
--   current scope contrasts against the code yet stays toned down — brighter
--   than the dim indent guides, not a harsh accent bar. The hl is re-applied on
--   ColorScheme because styler.nvim reloads colorschemes per filetype.
--
-- DRAWING IS OFF BY DEFAULT:
--   hlchunk.nvim (plugins/hlchunk.lua) answers the same "what block am I in"
--   question with a full ╭│╰ bracket, and it is on by default, so it sets
--   `vim.g.miniindentscope_disable` to silence this symbol rather than stack a
--   second vertical line beside it. <leader>uk swaps the two back and forth —
--   the lavender here is the same colour the bracket uses, so the indicator
--   keeps one identity across both shapes. The MOTIONS and TEXT OBJECTS above
--   are unaffected in either state: mini checks that flag only in its drawing
--   path, never in `operator` / `textobject`.

return {
  "echasnovski/mini.indentscope",
  version = "*",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local indentscope = require("mini.indentscope")
    indentscope.setup({
      symbol = "┊",
      options = { try_as_border = true },
      mappings = {
        goto_top             = "[i",
        goto_bottom          = "]i",
        object_scope         = "ii",
        object_scope_with_border = "ai",
      },
      draw = {
        animation = indentscope.gen_animation.none(),
      },
    })

    -- Soft, tinted scope color: a desaturated lavender that contrasts with the
    -- code but stays toned down. catppuccin Lavender (#b4befe).
    local function set_scope_hl()
      vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#b4befe", nocombine = true })
    end
    set_scope_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("SomyaIndentscopeHl", { clear = true }),
      callback = set_scope_hl,
    })
  end,
}
