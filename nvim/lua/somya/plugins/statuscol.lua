-- Custom gutter layout: git signs get their OWN column to the RIGHT of the line
-- number (nearest the code, easy to see), while everything else — marks,
-- diagnostics, and any future TODO/LSP signs — lives to the LEFT of the number.
-- The native sign column can't separate sources like this; statuscol.nvim routes
-- signs into segments by namespace, and de-dupes (git is claimed by its own
-- segment, so the catch-all left segment doesn't also draw it).
--
-- Pairs with signcolumn=no (statuscol reads signs from extmarks and sizes the
-- gutter itself) and ufo's foldcolumn (rendered via the builtin fold segment).
return {
  "luukvbaal/statuscol.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local builtin = require("statuscol.builtin")

    -- Per-window "two-column" line-number mode, toggled by <leader>ln (see
    -- core/keymaps.lua) via the window variable `ln_twocol`. The contract is
    -- just that window var, so the keymap and statuscol stay decoupled.
    local function two_col(args)
      local ok, v = pcall(vim.api.nvim_win_get_var, args.win, "ln_twocol")
      return ok and v == true
    end
    local function one_col(args)
      return not two_col(args)
    end
    -- Right-align a number within the number-column width.
    local function pad(n, width)
      local s = tostring(n)
      return (" "):rep(math.max(width - #s, 0)) .. s
    end
    -- Width of the relative (hybrid) column. It only ever holds small offsets
    -- (distance from the cursor), so 2 cells is plenty; pad() auto-grows for the
    -- rare 100+ offset rather than truncating.
    local REL_W = 2
    local function abs_lnum(args) -- absolute number column (full width)
      return pad(args.lnum, args.nuw)
    end
    local function hyb_lnum(args) -- relative offsets; BLANK on the cursor line
      -- The current line's number is already shown in the absolute column, so
      -- leave the hybrid cell blank there — this keeps the column at REL_W.
      if args.relnum == 0 then return (" "):rep(REL_W) end
      return pad(args.relnum, REL_W)
    end

    require("statuscol").setup({
      relculright = true, -- right-align the relative number (tidy hybrid mode)
      ft_ignore = {
        "alpha", "dashboard", "NvimTree", "neo-tree", "toggleterm", "lazy",
        "mason", "TelescopePrompt", "help", "qf", "trouble", "Outline", "aerial",
        "BookmarksTree",
      },
      segments = {
        -- 1. LEFT of number: all signs EXCEPT git (marks, diagnostics, TODO …).
        --    statuscol matches LEGACY signs (marks, todo-comments) by `name`
        --    and EXTMARK signs (diagnostics) by `namespace`, so we need both
        --    catch-alls here. git is de-duped out by the dedicated segment below.
        {
          sign = { name = { ".*" }, namespace = { ".*" }, maxwidth = 2, colwidth = 2, auto = false, wrap = true },
          click = "v:lua.ScSa",
        },
        -- 2a. normal number column (respects number/relativenumber) — default.
        { text = { builtin.lnumfunc, " " }, condition = { one_col, one_col }, click = "v:lua.ScLa" },
        -- 2b. two-column mode: absolute column + hybrid column side by side.
        { text = { abs_lnum, " " }, condition = { two_col, two_col }, click = "v:lua.ScLa" },
        { text = { hyb_lnum, " " }, condition = { two_col, two_col }, click = "v:lua.ScLa" },
        -- 3. fold column (ufo) between the number and the git signs, plus a
        --    space so the fold arrow and a git sign never touch
        { text = { builtin.foldfunc, " " }, click = "v:lua.ScFa" },
        -- 4. RIGHT of number: dedicated git-signs column, always reserved so the
        --    code text never shifts when a change sign appears/disappears.
        {
          sign = { namespace = { "gitsigns" }, maxwidth = 1, colwidth = 1, auto = false, wrap = false },
          click = "v:lua.ScSa",
        },
        -- 5. one space so the git sign doesn't butt up against the code
        { text = { " " } },
      },
    })
  end,
}
