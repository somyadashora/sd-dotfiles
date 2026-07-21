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
		local light = vim.o.background == "light"
		require("diagram").setup({
			integrations = { require("diagram.integrations.markdown") },
			renderer_options = {
				mermaid = {
					-- A SOLID background, not "transparent". The image backends we use
					-- (ueberzugpp's X11 overlay, and the kitty protocol inside tmux)
					-- don't composite a PNG's alpha channel, so a transparent mermaid
					-- render shows up as an empty black box with the diagram invisible
					-- inside it. Fill it with a color matching the editor background
					-- (catppuccin mocha base for dark) so the theme-colored diagram
					-- stays readable on top.
					background = light and "#ffffff" or "#1e1e2e",
					theme = light and "neutral" or "dark",
					scale = 2, -- crisper on hidpi; diagrams are downscaled to fit anyway
				},
			},
		})
	end,
}
