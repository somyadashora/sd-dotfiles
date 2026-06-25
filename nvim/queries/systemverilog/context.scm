;; extends

; nvim-treesitter-context ships a SystemVerilog context query that captures
; always/if/loop/instance but NOT case statements — so the sticky scope header
; would show the enclosing `always` block yet never the `case` or the matching
; entry. Add the case nodes here so you see the full nesting at once, like
; VSCode's sticky scroll:
;
;     always_ff @(posedge clk) begin     <- always_construct  (already shipped)
;       unique case (state)              <- case_statement     (added below)
;         FETCH: ...                      <- case_item          (added below)
;
; ";; extends" MERGES this file with the bundled query instead of replacing it,
; so the original always/if/loop/instance captures are preserved.
;
; Node names are from the gmlarumbe/tree-sitter-systemverilog grammar (the one
; nvim-treesitter installs). case_item covers plain + unique/priority case;
; case_inside_item is `case () inside`, case_pattern_item is pattern matching.
(case_statement) @context
(case_item) @context
(case_inside_item) @context
(case_pattern_item) @context

; ── Named scopes ────────────────────────────────────────────────────────────
; The bundled query captures `always_construct` (so a one-line
; `always_comb begin : new_logic` already shows the label) and
; `loop_generate_construct` (generate for-loops), but it misses procedural loops
; and nested named blocks. Add them so labelled scopes show in the header too.

; Procedural for/foreach/while/repeat/forever loops (none were captured before).
(loop_statement) @context

; Named begin blocks: `begin : label ... end`. Requiring the (simple_identifier)
; child means ONLY labelled blocks match — anonymous begin/end adds no noise.
; This also recovers the label of a named always whose `begin : name` sits on a
; line below the `always_*` keyword (which the always line alone would drop).
(seq_block (simple_identifier)) @context

; Named generate blocks: `... begin : gen_name`. The label is a `name:` field.
(generate_block name: (simple_identifier)) @context
