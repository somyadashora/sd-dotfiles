-- ══════════════════════════════════════════════════════════════════════════════
-- PLUGIN: vim-visual-multi  (mg979/vim-visual-multi)
-- Multiple cursors for Neovim — think VS Code Ctrl+D, but with Vim superpowers.
-- Quick help: <leader>mh    Full docs: :help visual-multi
-- ══════════════════════════════════════════════════════════════════════════════
--
-- ── CORE CONCEPT ─────────────────────────────────────────────────────────────
--
--   VM (Visual Multi) lets you place multiple cursors or selections across a
--   buffer and then type / edit at all of them simultaneously.
--
--   It has TWO internal modes (toggled with <Tab> while VM is active):
--
--     CURSOR MODE  (default) — each cursor behaves like a normal Vim cursor.
--                              Motions move all cursors. Editing happens at
--                              each cursor position independently.
--
--     EXTEND MODE            — each cursor has a selection attached to it,
--                              like multiple Visual selections at once.
--                              Use this when you need to replace whole words
--                              or regions, not just insert/append.
--
-- ── WORKFLOW 1: rename every occurrence of a word ────────────────────────────
--
--   This is the most common use-case (like VS Code Ctrl+D rename).
--
--   1. Place your cursor ON the word you want to rename.
--   2. Press <C-n>  →  VM starts; the word is highlighted & a cursor placed.
--   3. Press <C-n> again (and again) to select the next occurrence each time.
--        - Press  q  to SKIP the current match and jump to the next one.
--        - Press  Q  to REMOVE the cursor at the current match.
--   4. Once all targets are selected, press  c  (change) — this deletes the
--      selected word and drops you into insert mode at every cursor.
--   5. Type the new name → it appears at all cursors simultaneously.
--   6. Press <Esc> to finish. VM exits automatically.
--
--   TIP: Press <leader>ma instead of repeating <C-n> to select ALL occurrences
--        in the file in one shot, then edit.
--
-- ── WORKFLOW 2: add a cursor on every line in a range ────────────────────────
--
--   Useful for prepending/appending the same text to many lines at once,
--   e.g. adding a comment prefix or a trailing comma.
--
--   1. Press <C-Down> repeatedly to add a cursor on each line below, OR:
--   2. Select lines in Visual mode first (V to select line range), then
--      press <C-n> — VM places one cursor per selected line.
--   3. Press  I  to go to the start of each line (or  A  for end).
--   4. Type whatever you want → it appears on all lines.
--   5. <Esc> to exit.
--
--   EXAMPLE — add "// " at the start of 5 lines:
--     Vjjjj        (select 5 lines in visual mode)
--     <C-n>        (VM activates with one cursor per line)
--     I            (insert at start of all lines)
--     // <Esc>     (type the prefix, exit insert, exit VM)
--
-- ── WORKFLOW 3: edit non-contiguous regions of different text ─────────────────
--
--   Sometimes the things you want to edit aren't the same word — they're just
--   in different places that need the same structural change.
--
--   1. Put cursor on first target, press <C-n> to start VM.
--   2. Move to the next target using NORMAL navigation (/, w, b, etc.) —
--      VM keeps your existing cursors while you navigate.
--   3. Press <C-n> again to add a cursor at the new position.
--   4. Repeat for all targets.
--   5. Edit normally — all cursors change simultaneously.
--
--   NOTE: while navigating between cursors you can press  ]  and  [  to
--         cycle through and visually inspect each cursor's position.
--
-- ── WORKFLOW 4: align code columns ───────────────────────────────────────────
--
--   Useful for aligning assignments or port maps in SystemVerilog:
--
--     input  wire clk,
--     input  wire rst,
--     output reg  data_out,
--
--   1. Select the lines (V + motion).
--   2. <C-n>  →  one cursor per line.
--   3. Move all cursors to the target column with a motion (e.g. f= to jump
--      to the '=' sign on each line).
--   4. Press  \ a  (VM leader + a) → VM aligns all cursors to the same column
--      by inserting spaces, so all '=' signs line up.
--
-- ── WORKFLOW 5: run a macro at all cursors ────────────────────────────────────
--
--   1. Record a macro normally: qq ... q
--   2. Add cursors at all targets (workflows 1–3 above).
--   3. Press  @q  while in VM → the macro runs at every cursor.
--
-- ── WORKFLOW 6: transpose / swap selections ───────────────────────────────────
--
--   Swap the content of two (or more) regions:
--
--   1. Add cursors on the two words/regions you want to swap.
--   2. Press <Tab> to switch to Extend mode (so each cursor has a selection).
--   3. Press  \ t  → synced transpose: each selection gets the content of
--      the next one (cyclic). Great for swapping two adjacent arguments.
--   4. Press  \ T  for unsynced transpose if the regions have different sizes.
--
-- ── TIPS & GOTCHAS ────────────────────────────────────────────────────────────
--
--   • <Esc> always exits VM completely and removes all cursors.
--
--   • VM doesn't interfere with your macros or registers — changes are
--     applied to the buffer normally, so undo (u) undoes the whole VM edit
--     as one atomic step.
--
--   • In CURSOR MODE, all standard Vim motions work: w, b, e, f, t, 0, $, etc.
--     They move ALL cursors at once, which can cause cursors to merge/split
--     in surprising ways — that's expected behaviour.
--
--   • In EXTEND MODE, motions extend each selection. Use  o  to jump the
--     active end of the selection between start and end (like Vim Visual o).
--
--   • The statusline shows the number of active cursors while VM is running
--     (configured with VM_set_statusline = 3).
--
--   • VM has its own leader key set to  \  (backslash) so its sub-commands
--     (\a, \t, \T, \s, \<, \>) don't conflict with your <Space> leader.
--
--   • <C-n> on a word with no more matches still exits gracefully.
--
--   • For full docs run:  :help visual-multi
--     For an interactive tutorial press  <leader>mt  — opens in a new tab.
--     (Or from your shell: nvim -Nu ~/.local/share/nvim/lazy/vim-visual-multi/tutorialrc)
--
-- ══════════════════════════════════════════════════════════════════════════════

return {
  "mg979/vim-visual-multi",
  branch = "master",
  event = { "BufReadPre", "BufNewFile" },
  init = function()
    -- Use backslash as VM-specific leader (keeps Space leader free)
    vim.g.VM_leader = "\\"

    -- Highlight theme
    vim.g.VM_theme = "ocean"

    -- Show cursors count in the statusline
    vim.g.VM_set_statusline = 3

    -- Customise a few maps; leave the rest at defaults
    vim.g.VM_maps = {
      -- keep Ctrl-N as "find under / add cursor"
      ["Find Under"]         = "<C-n>",
      ["Find Subword Under"] = "<C-n>",
      -- select-all occurrences of current word
      ["Select All"]         = "<leader>ma",
      -- add cursors with mouse (if supported)
      ["Mouse Cursor"]       = "<C-LeftMouse>",
      ["Mouse Word"]         = "<C-RightMouse>",
    }
  end,
  config = function()
    -- ── leader shortcut: <leader>mh → help popup ─────────────────────────
    local function open_help()
      local K = 22 -- key column width

      local sections = {
        {
          title = "START / ADD CURSORS",
          entries = {
            { "<C-n>",              "add cursor on word / find next match" },
            { "<C-n>  (visual)",    "add cursors on visual selection" },
            { "<C-Up> / <C-Down>",  "add cursor above / below" },
            { "<S-Left/Right>",     "extend selection char by char" },
            { "<leader>ma",         "select ALL occurrences of word" },
            { "<C-LeftMouse>",      "add cursor with mouse click" },
          },
        },
        {
          title = "NAVIGATE CURSORS / MATCHES",
          entries = {
            { "n / N",              "next / previous match" },
            { "] / [",              "select next / previous cursor" },
            { "q",                  "skip current match, move to next" },
            { "Q",                  "remove cursor / selection under pointer" },
          },
        },
        {
          title = "MODES",
          entries = {
            { "Tab",                "toggle cursor mode ↔ extend mode" },
            { "i / a / I / A",      "enter insert mode at cursor(s)" },
            { "o / O",              "extend mode: move to start / end" },
          },
        },
        {
          title = "EDIT AT ALL CURSORS",
          entries = {
            { "c / s / d",          "change / substitute / delete" },
            { "r<char>",            "replace char" },
            { "u / U",              "lower / upper case" },
            { "~",                  "toggle case" },
            { ". (dot)",            "repeat last change" },
            { "@<reg>",             "run macro at all cursors" },
          },
        },
        {
          title = "ALIGN / TRANSFORM",
          entries = {
            { "\\ a",               "align cursors" },
            { "\\ <  /  \\ >",     "shift selections left / right" },
            { "\\ t",               "transpose selections (synced)" },
            { "\\ T",               "transpose selections (unsynced)" },
            { "\\ s",               "split / trim whitespace in regions" },
          },
        },
        {
          title = "MISC",
          entries = {
            { "<Esc>",              "exit VM / clear all cursors" },
            { "<leader>mh",         "this help popup" },
            { ":help visual-multi", "full built-in documentation" },
            { "<leader>mt",         "open interactive tutorial (new tab)" },
          },
        },
      }

      local function make_sep(title)
        local prefix = "  ── " .. title .. " "
        return prefix .. string.rep("─", math.max(4, 74 - #prefix))
      end

      local lines, hl_title = {}, {}
      for _, section in ipairs(sections) do
        table.insert(lines, make_sep(section.title))
        table.insert(hl_title, #lines)
        for _, entry in ipairs(section.entries) do
          local key, desc = entry[1], entry[2]
          local pad = string.rep(" ", math.max(2, K - #key))
          table.insert(lines, "  " .. key .. pad .. desc)
        end
        table.insert(lines, "")
      end

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.bo[buf].bufhidden  = "wipe"
      vim.bo[buf].filetype   = "help"   -- basic syntax colouring

      local width  = math.min(78, math.floor(vim.o.columns * 0.88))
      local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.88))
      local row    = math.floor((vim.o.lines   - height) / 2)
      local col    = math.floor((vim.o.columns - width)  / 2)

      vim.api.nvim_open_win(buf, true, {
        relative  = "editor",
        width     = width,
        height    = height,
        row       = row,
        col       = col,
        style     = "minimal",
        border    = "rounded",
        title     = "  vim-visual-multi shortcuts  ",
        title_pos = "center",
      })

      local ns = vim.api.nvim_create_namespace("somya_vvm_help")
      for _, lnum in ipairs(hl_title) do
        vim.api.nvim_buf_add_highlight(buf, ns, "Title", lnum - 1, 0, -1)
      end

      for _, key in ipairs({ "q", "<Esc>", "<leader>mh" }) do
        vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
      end
    end

    vim.keymap.set("n", "<leader>mh", open_help, { desc = "vim-visual-multi shortcuts help" })

    -- ── <leader>mt → open the VM interactive tutorial in a new tab ───────
    vim.keymap.set("n", "<leader>mt", function()
      local tutorialrc = vim.fn.stdpath("data") .. "/lazy/vim-visual-multi/tutorialrc"
      if vim.fn.filereadable(tutorialrc) == 0 then
        vim.notify(
          "Tutorial file not found:\n" .. tutorialrc .. "\n\nIs the plugin installed? Run :Lazy sync",
          vim.log.levels.ERROR,
          { title = "vim-visual-multi" }
        )
        return
      end
      vim.cmd("tabnew")
      vim.cmd("terminal nvim -Nu " .. vim.fn.shellescape(tutorialrc))
      vim.cmd("startinsert") -- jump straight into the terminal so keys work
    end, { desc = "vim-visual-multi: open tutorial" })

    -- Convenience: show a brief hint when VM starts
    vim.api.nvim_create_autocmd("User", {
      pattern  = "visual_multi_start",
      callback = function()
        vim.notify("VM  <C-n> next · q skip · Q remove · Tab mode · <leader>mh help", vim.log.levels.INFO, { title = "vim-visual-multi" })
      end,
    })
  end,
}
