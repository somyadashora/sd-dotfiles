;; extends

; aerial's bundled SystemVerilog query lists modules/instances/interfaces/
; packages/generate/class/function/task but omits PROCEDURAL blocks. Add
; always / initial / final / fork here so they appear in the outline
; (:AerialToggle / <leader>oo).
;
; ";; extends" MERGES this with the bundled aerial query rather than replacing it
; (aerial loads via vim.treesitter.query.get(lang,"aerial")).
;
; ALWAYS blocks use TWO patterns, ordered to get the best label:
;   1. named  -> show the `begin : my_logic` label
;   2. unnamed -> fall back to the keyword (always_ff/always_comb/...)
; tree-sitter can't express "an always WITHOUT a label", so pattern 2 matches
; named blocks too — but ORDER saves us. tree-sitter yields matches in
; pattern-file order, so for a named always pattern 1 registers the
; always_construct node first; pattern 2 then hits the same node and aerial's
; same-node dedup drops it (get_parent returns last_node==node, so
; symbol_node==parent_node in init.lua). For an UNNAMED always pattern 1 can't
; match (no labelled seq_block), so only the keyword from pattern 2 survives.
; (Chain verified: aerial extensions.lua/init.lua + an iter_matches order test.)
;
; Node/keyword names verified against gmlarumbe/tree-sitter-systemverilog
; grammar.js: always_keyword is a named node (choice of always*/comb/ff/latch),
; the label is `(seq_block (simple_identifier))`, and 'initial'/'final'/'fork'
; are literal tokens that are direct children of their construct. kind "Function"
; keeps these within aerial's filter_kind.
;
; GENERATE blocks are already captured by the bundled query as kind "Namespace"
; (hidden by aerial's default filter_kind) — they're surfaced for SV by adding
; "Namespace" to filter_kind in plugins/aerial.lua, so no capture is added here.

; named always: label wins (listed first)
(always_construct
  (statement
    (statement_item
      (seq_block
        . (simple_identifier) @name)))
  (#set! "kind" "Function")) @type

; unnamed always: keyword fallback (deduped away when a label matched above)
(always_construct (always_keyword) @name (#set! "kind" "Function")) @type

; initial / final / fork: named by keyword
(initial_construct "initial" @name (#set! "kind" "Function")) @type
(final_construct "final" @name (#set! "kind" "Function")) @type
(par_block "fork" @name (#set! "kind" "Function")) @type
