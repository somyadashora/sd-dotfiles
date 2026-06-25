;; extends

; aerial's bundled SystemVerilog query lists modules/instances/interfaces/
; packages/generate/class/function/task but omits PROCEDURAL blocks. Add
; always / initial / final / fork here so they appear in the outline
; (:AerialToggle / <leader>oo).
;
; ";; extends" MERGES this with the bundled aerial query rather than replacing it
; (aerial loads via vim.treesitter.query.get(lang,"aerial")).
;
; Each block is captured ONCE, named by its KEYWORD (always_ff/always_comb/
; initial/final/fork). For a NAMED always (`begin : my_logic`) the keyword name is
; then upgraded to the label by the post_parse_symbol hook in plugins/aerial.lua.
;
; Why the label isn't a second query pattern: tree-sitter can't express "an always
; WITHOUT a label", so a label pattern would also need a keyword fallback, and the
; two would BOTH match a named always. aerial keeps only one (same-node dedup) and
; the KEYWORD always wins — tree-sitter yields the shallow keyword match before the
; deep label match regardless of file order (verified with an iter_matches test).
; So the label has to be applied in Lua, where it's order-independent.
;
; Node/keyword names verified against gmlarumbe/tree-sitter-systemverilog
; grammar.js: always_keyword is a named node (choice of always*/comb/ff/latch);
; 'initial'/'final'/'fork' are literal tokens that are direct children of their
; construct. kind "Function" keeps these within aerial's filter_kind.
;
; GENERATE blocks are already captured by the bundled query as kind "Namespace"
; (hidden by aerial's default filter_kind) — they're surfaced for SV by adding
; "Namespace" to filter_kind in plugins/aerial.lua, so no capture is added here.

(always_construct (always_keyword) @name (#set! "kind" "Function")) @type
(initial_construct "initial" @name (#set! "kind" "Function")) @type
(final_construct "final" @name (#set! "kind" "Function")) @type
(par_block "fork" @name (#set! "kind" "Function")) @type
