 local function fold_text_with_count(chunks, start_lnum, end_lnum, width, truncate)
    local out = {}
    -- "  ┄ 15 lines " — the ┄ dash echoes the fold guide's dotted motif,
    -- and the tag is drawn in SomyaFoldCount (same sapphire-grey as the fold
    -- triangles, set in init) so the collapsed-line count reads as part of
    -- the fold styling.
    local suffix = ("  ┄ %d lines "):format(end_lnum - start_lnum)
    local suffix_w = vim.fn.strdisplaywidth(suffix)
    local target_w = width - suffix_w
    local used = 0

    for _, chunk in ipairs(chunks) do
      local text, hl = chunk[1], chunk[2]
      local w = vim.fn.strdisplaywidth(text)
      if used + w <= target_w then
        table.insert(out, { text, hl })
        used = used + w
      else
        local cut = truncate(text, math.max(target_w - used, 0))
        table.insert(out, { cut, hl })
        used = used + vim.fn.strdisplaywidth(cut)
        break
      end
    end

    if used < target_w then
      suffix = string.rep(" ", target_w - used) .. suffix
    end
    table.insert(out, { suffix, "SomyaFoldCount" })
    return out
  end

  return {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      -- Fold-arrow column starts hidden to keep the gutter narrow; <leader>uf
      -- (core/keymaps.lua) shows it per-window. Folding itself (za/zR/zM, the
      -- fold text below) works regardless of the column.
      vim.o.foldcolumn = "0"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.opt.fillchars = vim.tbl_extend("force", vim.opt.fillchars:get(), {
        eob      = " ",
        fold     = " ",
        foldopen = "▼",  -- down-pointing triangle
        foldsep  = "\u{2506}",   -- ┆ triple-dash dotted guide (distinct rhythm
                                 -- from indentscope's ┊ quadruple-dash)
        foldclose= "▶",  -- right-pointing triangle
        foldinner= " ",
      })

      -- Tone down the fold column (triangles + ┆ guide, all FoldColumn-hl'd) to a
      -- soft desaturated sapphire-grey: visible in the gutter and cool-tinted so
      -- it reads as "fold", but quiet enough not to fight the grey indent guides
      -- or the lavender indentscope line. CursorLineFold is a touch brighter so
      -- the cursor's fold char still stands out. Re-applied on ColorScheme
      -- because styler.nvim reloads colorschemes per filetype.
      local function set_fold_hl()
        vim.api.nvim_set_hl(0, "FoldColumn", { fg = "#7ba0c4" })
        vim.api.nvim_set_hl(0, "CursorLineFold", { fg = "#a6c2e0" })
        -- Inline "┄ N lines" tag on a collapsed fold: same sapphire-grey as the
        -- triangles, italic so it reads as a soft annotation rather than code.
        vim.api.nvim_set_hl(0, "SomyaFoldCount", { fg = "#7ba0c4", italic = true })
      end
      set_fold_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("SomyaFoldColumnHl", { clear = true }),
        callback = set_fold_hl,
      })
    end,
    opts = {
      provider_selector = function() return { "indent" } end,
      fold_virt_text_handler = fold_text_with_count,
    },
    keys = {
      { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
    },
  }
