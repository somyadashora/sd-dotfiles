return {
	dir = vim.fn.stdpath("config"),
	name = "dot-peek",
	lazy = false,
	config = function()
		local buf, win
		local visible = false

		-- op_snapshot: normal-mode keys that triggered the last insert (e.g. "ciw", "A", "5s")
		-- persists until the next insert operation so the window always shows the full command
		local op_snapshot = ""
		local nkeys = ""
		local nkeys_timer = nil

		local function reset_nkeys()
			nkeys = ""
			if nkeys_timer then nkeys_timer:stop(); nkeys_timer:close(); nkeys_timer = nil end
		end

		-- Accumulate keys in normal AND operator-pending mode so "ciw" is captured whole.
		-- Navigation keys (j, k, w, …) also start in "n" but they trigger CursorMoved
		-- which resets the accumulator before any operator key is appended.
		vim.on_key(function(key)
			local mode = vim.fn.mode()
			if mode ~= "n" and mode ~= "no" then return end
			local k = vim.fn.keytrans(key)
			if k == "" then return end
			nkeys = nkeys .. k
			if #nkeys > 20 then nkeys = nkeys:sub(-20) end
			if nkeys_timer then nkeys_timer:stop(); nkeys_timer:close() end
			nkeys_timer = vim.uv.new_timer()
			nkeys_timer:start(3000, 0, vim.schedule_wrap(reset_nkeys))
		end)

		-- Navigation keys move the cursor while still in "n" mode — reset there so they
		-- don't bleed into the next operator snapshot. Operator motions run in "no" mode
		-- so this autocmd leaves them untouched.
		vim.api.nvim_create_autocmd("CursorMoved", {
			callback = function()
				if vim.fn.mode() == "n" then reset_nkeys() end
			end,
		})

		-- When entering insert/replace mode, snapshot the triggering keys
		vim.api.nvim_create_autocmd("ModeChanged", {
			pattern = { "*:i*", "*:R*" },
			callback = function()
				if nkeys ~= "" then op_snapshot = nkeys end
				reset_nkeys()
			end,
		})

		local HL = "DotPeek"

		local function set_hl()
			vim.api.nvim_set_hl(0, HL, { fg = "#cdd6f4", italic = true, bg = "#1e2535" })
		end
		set_hl()
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("dot_peek_hl", { clear = true }),
			callback = set_hl,
		})

		local function build_content()
			local ins = vim.fn.getreg(".")
			if ins == nil or ins == "" then return nil end
			ins = ins:gsub("\n", "\\n")
			if #ins > 30 then ins = ins:sub(1, 27) .. "…" end
			if op_snapshot ~= "" then
				return op_snapshot .. "  │  " .. ins
			end
			return ins
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
			local content = build_content()
			local line = content and ("  " .. content .. "  ") or "  (empty)  "
			local width = math.max(12, vim.fn.strdisplaywidth(line))
			vim.bo[buf].modifiable = true
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
			vim.bo[buf].modifiable = false
			if win and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_set_config(win, win_config(width))
			end
		end

		local function open()
			buf = vim.api.nvim_create_buf(false, true)
			vim.bo[buf].bufhidden = "wipe"
			local content = build_content()
			local line = content and ("  " .. content .. "  ") or "  (empty)  "
			local width = math.max(12, vim.fn.strdisplaywidth(line))
			win = vim.api.nvim_open_win(buf, false, win_config(width))
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
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
			else
				open()
				visible = true
			end
		end

		-- Dot register updates at InsertLeave; re-render then
		vim.api.nvim_create_autocmd("InsertLeave", {
			callback = function()
				if visible then vim.schedule(render) end
			end,
		})

		vim.api.nvim_create_autocmd("VimResized", {
			callback = function()
				if visible then vim.schedule(render) end
			end,
		})

		vim.keymap.set("n", "<leader>.", toggle, { desc = "Toggle dot-register peek" })
	end,
}
