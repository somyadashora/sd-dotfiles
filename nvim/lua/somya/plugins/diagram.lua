-- Diagrams-as-code rendered in the buffer: extracts ```mermaid fences (plus
-- plantuml/d2/gnuplot, if those CLIs exist) from markdown and draws the
-- rendered picture over the block through image.nvim — so it works on any
-- terminal image.nvim's backend supports (see image.lua), and the file itself
-- is never touched. Re-renders on BufWinEnter/InsertLeave/TextChanged.
-- Mermaid needs the mermaid CLI: `npm i -g @mermaid-js/mermaid-cli` (node +
-- headless chromium; without it the fence just stays as text). The diagram
-- theme follows 'background' (dark scheme → dark diagrams), matching how the
-- rest of the config themes itself.
return {
	"3rd/diagram.nvim",
	ft = { "markdown" },
	dependencies = { "3rd/image.nvim" },
	config = function()
		require("diagram").setup({
			integrations = { require("diagram.integrations.markdown") },
			renderer_options = {
				mermaid = {
					background = "transparent",
					theme = vim.o.background == "light" and "neutral" or "dark",
					scale = 2, -- crisper on hidpi; diagrams are downscaled to fit anyway
				},
			},
		})
	end,
}
