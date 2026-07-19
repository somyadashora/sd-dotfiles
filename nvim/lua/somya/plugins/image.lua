-- Inline images drawn over the buffer: image.nvim renders markdown image links
-- (![...](path), incl. remote URLs via curl) as real pictures, and is the
-- display engine diagram.nvim (mermaid) plugs into. Chosen over snacks.image
-- because of its ueberzugpp backend: snacks only speaks the kitty graphics
-- protocol (kitty/ghostty terminals), while ueberzugpp overlays an X11 window
-- on top of ANY terminal — so images work on ETX/SLES machines with a DISPLAY,
-- no special terminal needed. The backend is picked per machine at startup:
--   kitty/ghostty terminal → "kitty" protocol (fastest, clips/scrolls natively)
--   `ueberzugpp` on PATH   → "ueberzug" X11 overlay (any terminal + $DISPLAY)
--   neither                → "kitty" escapes, a harmless no-op on dumb terminals
-- Runtime requirements (none installed by the installers): ImageMagick CLI
-- (processor = "magick_cli"; build = false skips the luarocks magick rock),
-- `ueberzugpp` for the X11 backend, curl for remote images. Inside tmux the
-- kitty path needs allow-passthrough + focus-events (set in .tmux.conf).
local function pick_backend()
	local term = (vim.env.TERM or "") .. " " .. (vim.env.TERM_PROGRAM or "")
	if vim.env.KITTY_WINDOW_ID or term:lower():match("kitty") or term:lower():match("ghostty") then
		return "kitty"
	end
	if vim.fn.executable("ueberzugpp") == 1 then
		return "ueberzug"
	end
	return "kitty"
end

return {
	"3rd/image.nvim",
	build = false, -- no luarocks: magick_cli shells out to ImageMagick instead
	event = "VeryLazy", -- not ft-gated: also hijacks *.png/*.jpg… buffers into previews
	opts = {
		backend = pick_backend(),
		processor = "magick_cli",
		integrations = {
			markdown = {
				enabled = true,
				-- vault notes may carry telekasten's own filetype
				filetypes = { "markdown", "telekasten" },
				download_remote_images = true,
				only_render_image_at_cursor = false,
				clear_in_insert_mode = false,
			},
		},
		max_height_window_percentage = 50,
		-- ueberzug overlays don't move with tmux pane switches — hide instead of ghosting
		tmux_show_only_in_active_window = true,
	},
}
