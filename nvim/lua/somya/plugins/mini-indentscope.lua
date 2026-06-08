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
--   The scope is highlighted with a │ line through the indent-blankline guides.

return {
  "echasnovski/mini.indentscope",
  version = "*",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local indentscope = require("mini.indentscope")
    indentscope.setup({
      symbol = "│",
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
  end,
}
