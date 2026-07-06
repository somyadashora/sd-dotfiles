-- vim-sneak — multi-line f/F/t/T + the 2-char `s` sneak motion.
--
-- Native f/F/t/T stop at the current line; sneak's <Plug>Sneak_f/t versions
-- (opt-in, mapped below) search the whole buffer, and `;` / `,` repeats cross
-- lines too. All four are mapped in n/x/o so they still work as operator
-- targets (df.  ct)) and in visual mode.
--
-- The plugin's headline 2-char motion rides along: `s{ab}` jumps forward to
-- "ab", `S{ab}` backward. Mode-specific keys follow sneak's own defaults so
-- they can't collide with nvim-surround: visual-mode backward is `Z` (visual
-- `S` stays surround-selection), operator-pending uses `z`/`Z` (so `dz{ab}`,
-- and surround's ds/cs/ys are untouched). Native `s` is `cl` if ever missed.
--
-- Everything is declared via lazy.nvim `keys`, so the plugin loads on the
-- first motion press and `s` behaves the same before/after any `f`.
return {
  "justinmk/vim-sneak",
  keys = {
    -- 1-char sneak = f/F/t/T that cross lines
    { "f", "<Plug>Sneak_f", mode = { "n", "x", "o" }, desc = "f (multi-line, sneak)" },
    { "F", "<Plug>Sneak_F", mode = { "n", "x", "o" }, desc = "F (multi-line, sneak)" },
    { "t", "<Plug>Sneak_t", mode = { "n", "x", "o" }, desc = "t (multi-line, sneak)" },
    { "T", "<Plug>Sneak_T", mode = { "n", "x", "o" }, desc = "T (multi-line, sneak)" },
    -- 2-char sneak
    { "s", "<Plug>Sneak_s", mode = { "n", "x" }, desc = "Sneak 2-char forward" },
    { "S", "<Plug>Sneak_S", mode = "n", desc = "Sneak 2-char backward" },
    { "Z", "<Plug>Sneak_S", mode = "x", desc = "Sneak 2-char backward" },
    { "z", "<Plug>Sneak_s", mode = "o", desc = "Sneak 2-char forward" },
    { "Z", "<Plug>Sneak_S", mode = "o", desc = "Sneak 2-char backward" },
  },
}
