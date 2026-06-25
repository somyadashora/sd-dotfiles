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
