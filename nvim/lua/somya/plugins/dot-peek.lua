return {
	dir = vim.fn.stdpath("config"),
	name = "dot-peek",
	lazy = false,
	config = function()
		local buf, win
		local visible = false

		local HL = "DotPeek"
		local HL_TITLE = "DotPeekTitle"

		local function set_hl()
			vim.api.nvim_set_hl(0, HL, { fg = "#cdd6f4", italic = true, bg = "#1e2535" })
			vim.api.nvim_set_hl(0, HL_TITLE, { fg = "#f9e2af", bold = true, bg = "#1e2535" })
		end
		set_hl()
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("dot_peek_hl", { clear = true }),
			callback = set_hl,
		})

		local function dot_text()
			local txt = vim.fn.getreg(".")
			if txt == nil or txt == "" then return nil end
			txt = txt:gsub("\n", "\\n")
			if #txt > 44 then txt = txt:sub(1, 41) .. "…" end
			return txt
		end

		local function win_config(width)
			return {
				relative  = "editor",
				width     = width,
				height    = 1,
				row       = vim.o.lines - 5,
				col       = vim.o.columns - width - 4,
				style     = "minimal",
				border    = "rounded",
				focusable = false,
				zindex    = 200,
				title     = " 󰑖 . ",
				title_pos = "center",
			}
		end

		local function render()
			if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
			local txt = dot_text()
			local content = txt and ("  " .. txt .. "  ") or "  (empty)  "
			local width = math.max(12, vim.fn.strdisplaywidth(content))
			vim.bo[buf].modifiable = true
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { content })
			vim.bo[buf].modifiable = false
			if win and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_set_config(win, win_config(width))
			end
		end

		local function open()
			buf = vim.api.nvim_create_buf(false, true)
			vim.bo[buf].bufhidden = "wipe"

			local txt = dot_text()
			local content = txt and ("  " .. txt .. "  ") or "  (empty)  "
			local width = math.max(12, vim.fn.strdisplaywidth(content))

			win = vim.api.nvim_open_win(buf, false, win_config(width))
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { content })
			vim.bo[buf].modifiable = false
			vim.wo[win].winhl = "Normal:" .. HL
		end

		local function close()
			if win and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			win = nil
			buf = nil
		end

		local function toggle()
			if visible then
				close()
				visible = false
				vim.notify("Dot-peek hidden", vim.log.levels.INFO)
			else
				open()
				visible = true
				vim.notify("Dot-peek visible", vim.log.levels.INFO)
			end
		end

		-- Refresh after leaving insert (dot register updates on InsertLeave)
		vim.api.nvim_create_autocmd("InsertLeave", {
			callback = function()
				if visible then vim.schedule(render) end
			end,
		})

		-- Reposition when terminal is resized
		vim.api.nvim_create_autocmd("VimResized", {
			callback = function()
				if visible then vim.schedule(render) end
			end,
		})

		vim.keymap.set("n", "<leader>.", toggle, { desc = "Toggle dot-register peek" })
	end,
}
