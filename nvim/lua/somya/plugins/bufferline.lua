return {
  "akinsho/bufferline.nvim",
  -- Lazy: UI element, load just after startup instead of blocking it. Also
  -- defers its scope.nvim dependency (~6ms) off the critical path.
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    -- scopes buffers to the tab they were opened in
    { "tiagovla/scope.nvim", config = true },
  },
  version = "*",
  config = function()
    -- In a big SV project every file is <ProjectTag><Module>.sv, so the head of
    -- the name is the part that carries no information — and bufferline's own
    -- truncation keeps exactly that head ("MyProjectM.."). Two steps fix it:
    -- strip the prefix every open buffer shares, then, if still too long, cut
    -- from the LEFT so the distinguishing tail (…ModuleLRU.sv) always survives.
    local MAX_NAME   = 22 -- widest name we render before shortening
    local MIN_PREFIX = 4  -- shorter shared prefixes aren't worth an ellipsis
    local ELLIPSIS   = "…"

    -- Longest common prefix of the basenames of all listed buffers. Recomputed
    -- only when the buffer set changes (cached) — name_formatter is called for
    -- every buffer on every tabline redraw. scope.nvim unlists out-of-tab
    -- buffers, so this naturally follows the tab's own buffer set.
    local prefix_cache = nil
    local function shared_prefix()
      if prefix_cache then return prefix_cache end
      local lcp, count = nil, 0
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local path = vim.api.nvim_buf_get_name(b)
        if vim.bo[b].buflisted and path ~= "" then
          local name = vim.fn.fnamemodify(path, ":t")
          count = count + 1
          if not lcp then
            lcp = name
          else
            local i = 0
            while i < #lcp and i < #name and lcp:byte(i + 1) == name:byte(i + 1) do
              i = i + 1
            end
            lcp = lcp:sub(1, i)
            if lcp == "" then break end
          end
        end
      end
      -- one buffer is its own prefix — stripping it would blank the name
      prefix_cache = (count > 1 and lcp) or ""
      return prefix_cache
    end

    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufFilePost", "TabEnter" }, {
      group = vim.api.nvim_create_augroup("BufferlineNamePrefix", { clear = true }),
      callback = function() prefix_cache = nil end,
    })

    local function shorten(buf)
      local name = buf.name
      local prefix = shared_prefix()
      -- keep at least 3 chars after the cut, else the strip tells you nothing
      if #prefix >= MIN_PREFIX and #name > #prefix + 3 then
        name = ELLIPSIS .. name:sub(#prefix + 1)
      end
      local chars = vim.fn.strchars(name)
      if chars > MAX_NAME then
        name = ELLIPSIS .. vim.fn.strcharpart(name, chars - MAX_NAME + 1)
      end
      return name
    end

    local opts = {
      options = {
        mode                 = "buffers",
        separator_style      = "slant",
        name_formatter       = shorten,
        -- shorten() already caps the name, so bufferline's head-keeping
        -- truncation must never fire on top of it
        max_name_length      = MAX_NAME,
        truncate_names       = false,
        always_show_bufferline = true,
        show_buffer_icons    = true,
        color_icons          = true,
        buffer_close_icon    = "󰅖",
        close_icon           = "󰅖",
        modified_icon        = "●",
        offsets = {
          {
            filetype  = "NvimTree",
            text      = "File Explorer",
            text_align = "left",
            separator = true,
          },
        },
      },
    }

    require("bufferline").setup(opts)

    -- bufferline derives its highlights from the colorscheme only at setup time,
    -- so re-run setup on every colorscheme switch to keep the tabline in sync.
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("BufferlineFollowColorscheme", { clear = true }),
      callback = function() require("bufferline").setup(opts) end,
    })

    local keymap = vim.keymap
    keymap.set("n", "<S-h>",       "<cmd>BufferLineCyclePrev<cr>",   { desc = "Prev buffer" })
    keymap.set("n", "<S-l>",       "<cmd>BufferLineCycleNext<cr>",   { desc = "Next buffer" })
    keymap.set("n", "<leader>bg",  "<cmd>BufferLinePick<cr>",        { desc = "Pick buffer by letter" })
    keymap.set("n", "<leader>bn",  "<cmd>BufferLineCycleNext<cr>",   { desc = "Next buffer" })
    keymap.set("n", "<leader>bp",  "<cmd>BufferLineCyclePrev<cr>",   { desc = "Prev buffer" })
    keymap.set("n", "<leader>bcr", "<cmd>BufferLineCloseRight<cr>",  { desc = "Close buffers to the right" })
    keymap.set("n", "<leader>bcl", "<cmd>BufferLineCloseLeft<cr>",   { desc = "Close buffers to the left" })
    keymap.set("n", "<leader>bco", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close other buffers" })
    keymap.set("n", "<leader>bC",  "<cmd>BufferLinePickClose<cr>",   { desc = "Pick buffer to close" })
  end,
}
