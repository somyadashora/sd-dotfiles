 local function fold_text_with_count(chunks, start_lnum, end_lnum, width, truncate)
    local out = {}
    local suffix = ("   %d lines "):format(end_lnum - start_lnum)
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
    table.insert(out, { suffix, "Comment" })
    return out
  end

  return {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.opt.fillchars = vim.tbl_extend("force", vim.opt.fillchars:get(), {
        eob      = " ",
        fold     = " ",
        foldopen = "▼",  -- down-pointing triangle
        foldsep  = "\u{2502}",   -- │ vertical guide
        foldclose= "▶",  -- right-pointing triangle
        foldinner= " ",
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
