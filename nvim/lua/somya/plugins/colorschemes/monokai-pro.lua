return {
-- Monokai Pro theme with multiple filters: Pro, Classic, Machine, Octagon,
-- Ristretto, Spectrum.
{
  'loctvl842/monokai-pro.nvim',
   -- Only used by styler.nvim for per-filetype HDL schemes. styler lists this as
   -- a dependency, so it loads (and applies opts) when styler loads on VeryLazy,
   -- instead of as a priority-1000 startup colorscheme.
   lazy = true,
   opts = {
     filter = 'pro', -- classic | octagon | pro | machine | ristretto | spectrum
     styles = {
       -- Off at the source too (core/theme.lua's de-italic pass would strip it
       -- anyway): faked italics overhang the character cell and get clipped on
       -- terminals without a real italic face. See theme.M.italic_comments.
       comment = { italic = false },
       keyword = { italic = false }, -- any other keyword
       type = { italic = false }, -- (preferred) int, long, char, etc
       storageclass = { italic = false }, -- static, register, volatile, etc
       structure = { italic = false }, -- struct, union, enum, etc
       parameter = { italic = false }, -- parameter pass in function
       annotation = { italic = false },
       tag_attribute = { italic = false }, -- attribute of tag in reactjs
     },
     plugins = {
       bufferline = {
         underline_selected = false,
         underline_visible = false,
       },
       indent_blankline = {
         context_highlight = 'pro', -- default | pro
         context_start_underline = false,
       },
     },
   },
},
}
