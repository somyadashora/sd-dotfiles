;; extends

; aerial's bundled SystemVerilog query lists modules/instances/interfaces/
; packages/generate/class/function/task but omits PROCEDURAL blocks. Add
; always / initial / final / fork here so they appear in the outline
; (:AerialToggle / <leader>oo).
;
; ";; extends" MERGES this with the bundled aerial query rather than replacing it
; (aerial loads via vim.treesitter.query.get(lang,"aerial")).
;
; Each block is named by its KEYWORD (always_ff/always_comb/initial/final/fork),
; not by a `begin : label`. Reason: tree-sitter can't express "an always WITHOUT
; a label", so a label-capture plus a keyword-capture would BOTH match a named
; always and double-list it (aerial only dedupes parent==child, not two captures
; of one node). The keyword covers named AND unnamed blocks uniformly; a
; `begin : my_logic` label still shows in the sticky context header.
;
; Node/keyword names verified against gmlarumbe/tree-sitter-systemverilog
; grammar.js: always_keyword is a named node (choice of always*/comb/ff/latch);
; 'initial'/'final'/'fork' are literal tokens that are direct children of their
; construct. kind "Function" keeps them within aerial's filter_kind.
;
; GENERATE blocks are already captured by the bundled query as kind "Namespace"
; (hidden by aerial's default filter_kind) — they're surfaced for SV by adding
; "Namespace" to filter_kind in plugins/aerial.lua, so no capture is added here.

(always_construct (always_keyword) @name (#set! "kind" "Function")) @type
(initial_construct "initial" @name (#set! "kind" "Function")) @type
(final_construct "final" @name (#set! "kind" "Function")) @type
(par_block "fork" @name (#set! "kind" "Function")) @type
